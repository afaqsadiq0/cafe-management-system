import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/repository_providers.dart';
import '../domain/orders_providers.dart';
import 'order_taking_screen.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, String> _orderChefs = {};
  Map<String, DateTime> _orderTargetTimes = {};
  bool _isManualRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadChefAndTimerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChefAndTimerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      if (!mounted) return;
      setState(() {
        for (final key in keys.where((k) => k.startsWith('chef_'))) {
          _orderChefs[key.substring(5)] = prefs.getString(key) ?? '';
        }
        for (final key in keys.where((k) => k.startsWith('timer_'))) {
          final val = prefs.getString(key);
          if (val != null) {
            _orderTargetTimes[key.substring(6)] = DateTime.parse(val);
          }
        }
      });
    } catch (_) {}
  }

  List<Map<String, dynamic>> _filterByTab(List<Map<String, dynamic>> allOrders, int tabIndex) {
    return allOrders.where((order) {
      final status = (order['status'] ?? 'pending').toString().toLowerCase().trim();
      switch (tabIndex) {
        case 0:
          return true;
        case 1:
          return status == 'pending';
        case 2:
          return status == 'preparing';
        case 3:
          return status == 'ready' || status == 'completed' || status == 'done' || status == 'complete';
        case 4:
          return status == 'cancelled' || status == 'canceled';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.secondaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.secondaryColor,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Preparing'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
        actions: [
          IconButton(
            icon: _isManualRefreshing
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                      ),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isManualRefreshing
                ? null
                : () async {
                    setState(() => _isManualRefreshing = true);
                    try {
                      ref.invalidate(ordersListProvider);
                      await ref.read(ordersListProvider.future);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Orders list refreshed successfully! 🔄'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppTheme.secondaryColor,
                          ),
                        );
                      }
                    } catch (_) {
                    } finally {
                      if (mounted) {
                        setState(() => _isManualRefreshing = false);
                      }
                    }
                  },
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Could not load orders',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(ordersListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (allOrders) => RefreshIndicator(
          color: AppTheme.secondaryColor,
          onRefresh: () async {
            ref.invalidate(ordersListProvider);
            await ref.read(ordersListProvider.future);
          },
          child: TabBarView(
            controller: _tabController,
            children: List.generate(
              5,
              (tabIndex) => _OrdersTabList(
                orders: _filterByTab(allOrders, tabIndex),
                orderChefs: _orderChefs,
                orderTargetTimes: _orderTargetTimes,
                onStatusChanged: (orderId, newStatus) async {
                  final orderRepo = ref.read(orderRepositoryProvider);
                  final notifier = ref.read(orderNotificationServiceProvider);
                  try {
                    await orderRepo.updateOrderStatus(orderId, newStatus);
                    // Wait for Supabase to fully process the update
                    await Future.delayed(const Duration(milliseconds: 600));
                    ref.invalidate(ordersListProvider);
                    await notifier.notifyOrderStatusChange(orderId, newStatus);
                    if (context.mounted) {
                      notifier.triggerStatusNotification(context, orderId, newStatus);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Order marked as ${newStatus[0].toUpperCase()}${newStatus.substring(1)} ✅'),
                          backgroundColor: newStatus == 'completed' ? Colors.green : newStatus == 'cancelled' ? Colors.red : Colors.blue,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update order status: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: OpenContainer(
        transitionType: ContainerTransitionType.fade,
        transitionDuration: const Duration(milliseconds: 400),
        openBuilder: (context, _) => const OrderTakingScreen(),
        closedElevation: 6.0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        closedColor: AppTheme.secondaryColor,
        closedBuilder: (context, openContainer) {
          return FloatingActionButton(
            elevation: 0,
            onPressed: openContainer,
            backgroundColor: AppTheme.secondaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }
}

class _OrdersTabList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final Map<String, String> orderChefs;
  final Map<String, DateTime> orderTargetTimes;
  final Future<void> Function(String orderId, String newStatus) onStatusChanged;

  const _OrdersTabList({
    required this.orders,
    required this.orderChefs,
    required this.orderTargetTimes,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No orders found here! ☕',
              style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: PageStorageKey('orders_${orders.length}_${orders.first['id']}'),
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(
          order: order,
          chefName: orderChefs[order['id']],
          targetTime: orderTargetTimes[order['id']],
          onStatusChanged: onStatusChanged,
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String? chefName;
  final DateTime? targetTime;
  final Future<void> Function(String orderId, String newStatus) onStatusChanged;

  const _OrderCard({
    required this.order,
    this.chefName,
    this.targetTime,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = order['id'] as String;
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId;
    final total = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final status = (order['status'] ?? 'pending').toString();
    final method = order['payment_method'] ?? 'Cash';

    String timeAgo = 'Just now';
    if (order['created_at'] != null) {
      try {
        final dt = DateTime.parse(order['created_at'].toString()).toLocal();
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 1) {
          timeAgo = 'Just now';
        } else if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes} mins ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours} hours ago';
        } else {
          timeAgo = '${diff.inDays} days ago';
        }
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => context.push('/orders/$orderId/receipt'),
        title: Row(
          children: [
            Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(
              'PKR ${total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${order['notes'] != null && order['notes'].toString().isNotEmpty ? "${order['notes']} • " : ""}Method: $method • $timeAgo',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StatusChip(status: status),
                if (status.toLowerCase() == 'preparing')
                  _ChefTimerBadge(
                    chefName: chefName ?? 'Chef Hassan',
                    targetTime: targetTime,
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onSelected: (newStatus) => onStatusChanged(orderId, newStatus),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'pending',
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Text('Mark Pending'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'preparing',
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Text('Mark Preparing'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'completed',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Text('Mark Completed'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'cancelled',
              child: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Cancel Order'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.amber;
    final statusLower = status.toLowerCase();
    if (statusLower == 'preparing') color = Colors.blue;
    if (statusLower == 'ready') color = Colors.teal;
    if (statusLower == 'completed' || statusLower == 'done') color = Colors.green;
    if (statusLower == 'cancelled' || statusLower == 'canceled') color = Colors.red;

    final label = status.isNotEmpty
        ? '${status[0].toUpperCase()}${status.substring(1)}'
        : 'Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Own timer — does not rebuild the whole orders list every second.
class _ChefTimerBadge extends StatefulWidget {
  final String chefName;
  final DateTime? targetTime;

  const _ChefTimerBadge({required this.chefName, this.targetTime});

  @override
  State<_ChefTimerBadge> createState() => _ChefTimerBadgeState();
}

class _ChefTimerBadgeState extends State<_ChefTimerBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String countdown = '--:--';
    bool isReady = false;
    if (widget.targetTime != null) {
      final diff = widget.targetTime!.difference(DateTime.now());
      if (diff.isNegative) {
        countdown = 'READY 🔔';
        isReady = true;
      } else {
        final mins = diff.inMinutes.toString().padLeft(2, '0');
        final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
        countdown = '$mins:$secs';
      }
    }

    final badgeColor = isReady ? const Color(0xFF27AE60) : const Color(0xFF3498DB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            '👨‍🍳 ${widget.chefName} • $countdown',
            style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
