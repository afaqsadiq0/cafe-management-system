import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/repository_providers.dart';
import '../../orders/domain/orders_providers.dart';

class KdsScreen extends ConsumerStatefulWidget {
  const KdsScreen({super.key});

  @override
  ConsumerState<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends ConsumerState<KdsScreen> with TickerProviderStateMixin {
  late AnimationController _tickerController;
  
  // Local state for Chef name and countdown target times per order
  Map<String, String> _orderChefs = {}; // orderId -> Chef Name
  Map<String, DateTime> _orderTargetTimes = {}; // orderId -> Target Ready DateTime
  Set<String> _notifiedOrders = {}; // orderId

  @override
  void initState() {
    super.initState();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    
    // Add ticker listener to trigger rebuilds on every second tick for accurate countdowns
    _tickerController.addListener(() {
      setState(() {});
    });
    
    _loadChefAndTimerData();
  }

  Future<void> _loadChefAndTimerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final chefKeys = keys.where((k) => k.startsWith('chef_'));
      final timerKeys = keys.where((k) => k.startsWith('timer_'));
      
      setState(() {
        for (final key in chefKeys) {
          final orderId = key.substring(5);
          _orderChefs[orderId] = prefs.getString(key) ?? '';
        }
        for (final key in timerKeys) {
          final orderId = key.substring(6);
          final val = prefs.getString(key);
          if (val != null) {
            _orderTargetTimes[orderId] = DateTime.parse(val);
          }
        }
        _notifiedOrders = prefs.getStringList('kds_notified_orders')?.toSet() ?? {};
      });
    } catch (e) {
      debugPrint('Error loading KDS preferences: $e');
    }
  }

  Future<void> _saveChefAndTimer(
    String orderId,
    String chefName,
    int hours,
    int minutes,
    int seconds,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetTime = DateTime.now().add(
        Duration(hours: hours, minutes: minutes, seconds: seconds),
      );
      
      await prefs.setString('chef_$orderId', chefName);
      await prefs.setString('timer_$orderId', targetTime.toIso8601String());
      
      setState(() {
        _orderChefs[orderId] = chefName;
        _orderTargetTimes[orderId] = targetTime;
      });
    } catch (e) {
      debugPrint('Error saving KDS preferences: $e');
    }
  }

  Future<void> _clearChefAndTimer(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chef_$orderId');
      await prefs.remove('timer_$orderId');
      _notifiedOrders.remove(orderId);
      await prefs.setStringList('kds_notified_orders', _notifiedOrders.toList());
      
      setState(() {
        _orderChefs.remove(orderId);
        _orderTargetTimes.remove(orderId);
      });
    } catch (e) {
      debugPrint('Error clearing KDS preferences: $e');
    }
  }

  Future<void> _markOrderNotified(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notifiedOrders.add(orderId);
      await prefs.setStringList('kds_notified_orders', _notifiedOrders.toList());
    } catch (e) {
      debugPrint('Error marking notified order: $e');
    }
  }

  void _triggerOrderReadyNotification(String orderId) {
    if (_notifiedOrders.contains(orderId)) return;
    _markOrderNotified(orderId);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chefName = _orderChefs[orderId] ?? 'Chef Hassan';
      try {
        await ref.read(orderRepositoryProvider).updateOrderStatus(orderId, 'ready');
        ref.invalidate(ordersListProvider);
      } catch (e) {
        debugPrint('Failed to auto-update status to ready: $e');
      }

      ref.read(orderNotificationServiceProvider).notifyKitchenReady(orderId, chefName);
      if (mounted) {
        ref.read(orderNotificationServiceProvider).triggerStatusNotification(
          context,
          orderId,
          'Prepared by $chefName! Ready to serve 🍽️',
        );
      }
    });
  }

  String _getTimerCountdown(String orderId) {
    final targetTime = _orderTargetTimes[orderId];
    if (targetTime == null) return '--:--:--';

    final diff = targetTime.difference(DateTime.now());
    if (diff.isNegative) {
      _triggerOrderReadyNotification(orderId);
      return 'READY 🔔';
    }

    final h = diff.inHours;
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$m:$s';
    return '$m:$s';
  }

  String _formatReadyAt(String orderId) {
    final target = _orderTargetTimes[orderId];
    if (target == null) return '';
    final h = target.hour > 12 ? target.hour - 12 : (target.hour == 0 ? 12 : target.hour);
    final m = target.minute.toString().padLeft(2, '0');
    final s = target.second.toString().padLeft(2, '0');
    final period = target.hour >= 12 ? 'PM' : 'AM';
    return 'Ready at $h:$m:$s $period';
  }

  String _formatNowClock() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return 'Now $h:$m:$s $period';
  }

  @override
  void dispose() {
    _tickerController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _showChefAssignmentSheet(BuildContext context, String shortId) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChefAssignmentDialog(shortId: shortId),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFE67E22);
      case 'preparing':
        return const Color(0xFF3498DB);
      case 'ready':
        return const Color(0xFF008080);
      case 'completed':
      case 'done':
        return const Color(0xFF27AE60);
      case 'cancelled':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'preparing':
        return Icons.outdoor_grill_rounded;
      case 'ready':
        return Icons.check_circle_rounded;
      case 'completed':
      case 'done':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _elapsedTime(String? createdAt) {
    if (createdAt == null) return '0m';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      return '${diff.inHours}h';
    } catch (_) {
      return '—';
    }
  }

  bool _isUrgent(String? createdAt) {
    if (createdAt == null) return false;
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      return DateTime.now().difference(dt).inMinutes >= 15;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1117) : const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F1117) : const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.mounted ? Navigator.of(context).pop() : null,
        ),
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: Color(0xFF27AE60), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              'Kitchen Display',
              style: GoogleFonts.ebGaramond(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedBuilder(
              animation: _tickerController,
              builder: (context, _) {
                return Text(
                  _formatNowClock(),
                  style: GoogleFonts.hankenGrotesk(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Could not load kitchen orders', style: GoogleFonts.hankenGrotesk(color: Colors.white54)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(ordersListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (allOrders) {
          final activeOrders = allOrders.where((o) {
            final s = (o['status'] ?? '').toString().toLowerCase().trim();
            return s == 'pending' || s == 'preparing' || s == 'ready';
          }).toList();

          final pendingOrders = activeOrders.where((o) {
            final s = (o['status'] ?? '').toString().toLowerCase().trim();
            return s == 'pending';
          }).toList();
          final preparingOrders = activeOrders.where((o) {
            final s = (o['status'] ?? '').toString().toLowerCase().trim();
            return s == 'preparing' || s == 'ready';
          }).toList();

          if (activeOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.outdoor_grill_rounded, size: 72, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    'Kitchen is clear! ✨',
                    style: GoogleFonts.ebGaramond(color: Colors.white54, fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No active orders right now.',
                    style: GoogleFonts.hankenGrotesk(color: Colors.white30, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              // ── Pending Column ─────────────────────────────────────────
              Expanded(
                child: _buildStatusColumn(
                  context: context,
                  title: 'INCOMING',
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFE67E22),
                  orders: pendingOrders,
                  nextStatus: 'preparing',
                  nextLabel: 'Start Cooking',
                  nextIcon: Icons.outdoor_grill_rounded,
                  isDark: isDark,
                ),
              ),
              Container(width: 1, color: Colors.white10),

              // ── Preparing Column ────────────────────────────────────────
              Expanded(
                child: _buildStatusColumn(
                  context: context,
                  title: 'PREPARING',
                  icon: Icons.outdoor_grill_rounded,
                  color: const Color(0xFF3498DB),
                  orders: preparingOrders,
                  nextStatus: 'completed',
                  nextLabel: 'Complete Preparing',
                  nextIcon: Icons.check_circle_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusColumn({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> orders,
    required String nextStatus,
    required String nextLabel,
    required IconData nextIcon,
    required bool isDark,
  }) {
    return Column(
      children: [
        // Column Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          color: color.withOpacity(0.12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.hankenGrotesk(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${orders.length}',
                  style: GoogleFonts.hankenGrotesk(color: color, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        // Orders List
        Expanded(
          child: orders.isEmpty
              ? Center(
                  child: Text(
                    title == 'INCOMING' ? 'No new orders' : 'Nothing cooking',
                    style: GoogleFonts.hankenGrotesk(color: Colors.white30, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildKdsCard(context, order, color, nextStatus, nextLabel, nextIcon);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildKdsCard(
    BuildContext context,
    Map<String, dynamic> order,
    Color color,
    String nextStatus,
    String nextLabel,
    IconData nextIcon,
  ) {
    final orderId = order['id'] as String? ?? '';
    final shortId = orderId.length > 6 ? orderId.substring(0, 6).toUpperCase() : orderId;
    final elapsed = _elapsedTime(order['created_at']?.toString());
    final urgent = _isUrgent(order['created_at']?.toString());
    final orderRepo = ref.read(orderRepositoryProvider);
    
    final statusLower = order['status'].toString().toLowerCase();
    final isPreparing = statusLower == 'preparing' || statusLower == 'ready';
    final chefName = _orderChefs[orderId] ?? 'Chef Hassan';
    final timerCountdown = _getTimerCountdown(orderId);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: urgent ? const Color(0xFF2C1A0E) : const Color(0xFF1E2035),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: urgent ? const Color(0xFFE74C3C).withOpacity(0.5) : color.withOpacity(0.2),
            width: urgent ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$shortId',
                      style: GoogleFonts.hankenGrotesk(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (urgent) ...[
                    const Icon(Icons.warning_rounded, color: Color(0xFFE74C3C), size: 14),
                    const SizedBox(width: 3),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: urgent
                          ? const Color(0xFFE74C3C).withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_rounded, size: 12,
                            color: urgent ? const Color(0xFFE74C3C) : Colors.white54),
                        const SizedBox(width: 3),
                        Text(
                          elapsed,
                          style: GoogleFonts.hankenGrotesk(
                            color: urgent ? const Color(0xFFE74C3C) : Colors.white54,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Payment and Total Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded, size: 13, color: Colors.white38),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${order['payment_method'] ?? 'Cash'} • PKR ${(order['total_amount'] ?? 0.0).toStringAsFixed(0)}',
                      style: GoogleFonts.hankenGrotesk(color: Colors.white38, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 6),
            const Divider(color: Colors.white10, height: 1),

            // Ordered Items List
            FutureBuilder<List<Map<String, dynamic>>>(
              future: orderRepo.getOrderItems(orderId),
              builder: (context, itemSnapshot) {
                final items = itemSnapshot.data ?? [];
                if (items.isEmpty) {
                  return const SizedBox(height: 8);
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item['quantity']}x',
                                style: GoogleFonts.hankenGrotesk(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['item_name'] ?? 'Item',
                                style: GoogleFonts.hankenGrotesk(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            // Chef & Timer section (only when PREPARING)
            if (isPreparing) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: timerCountdown == 'READY 🔔' 
                        ? const Color(0xFF27AE60).withOpacity(0.12)
                        : const Color(0xFF3498DB).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: timerCountdown == 'READY 🔔' 
                          ? const Color(0xFF27AE60).withOpacity(0.3)
                          : const Color(0xFF3498DB).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.outdoor_grill_rounded,
                            size: 14,
                            color: timerCountdown == 'READY 🔔' ? const Color(0xFF27AE60) : const Color(0xFF3498DB),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '👨‍🍳 $chefName',
                              style: GoogleFonts.hankenGrotesk(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: timerCountdown == 'READY 🔔' 
                              ? const Color(0xFF27AE60)
                              : const Color(0xFF3498DB).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              timerCountdown == 'READY 🔔' ? Icons.notifications_active : Icons.timer_rounded, 
                              size: 11, 
                              color: timerCountdown == 'READY 🔔' ? Colors.white : const Color(0xFF3498DB)
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timerCountdown,
                              style: GoogleFonts.hankenGrotesk(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                        ],
                      ),
                      if (_formatReadyAt(orderId).isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _formatReadyAt(orderId),
                          style: GoogleFonts.hankenGrotesk(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 4),
            const Divider(color: Colors.white10, height: 1),

            // Action Button
            InkWell(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              onTap: () async {
                HapticFeedback.mediumImpact();
                
                if (nextStatus == 'preparing') {
                  final assignData = await _showChefAssignmentSheet(context, shortId);
                  if (assignData == null) return;

                  await _saveChefAndTimer(
                    orderId,
                    assignData['chefName'] as String,
                    assignData['hours'] as int,
                    assignData['minutes'] as int,
                    assignData['seconds'] as int,
                  );
                  await orderRepo.updateOrderStatus(orderId, nextStatus);
                  ref.invalidate(ordersListProvider);

                  if (context.mounted) {
                    final h = assignData['hours'] as int;
                    final m = assignData['minutes'] as int;
                    final s = assignData['seconds'] as int;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '🍳 ${assignData['chefName']} — timer ${h}h ${m}m ${s}s',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: const Color(0xFF3498DB),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else if (nextStatus == 'completed') {
                  await orderRepo.updateOrderStatus(orderId, nextStatus);
                  await _clearChefAndTimer(orderId);
                  ref.invalidate(ordersListProvider);
                  await ref.read(orderNotificationServiceProvider).notifyOrderStatusChange(orderId, 'completed');

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '✅ Order completed — moved to Completed tab!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Color(0xFF27AE60),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  await orderRepo.updateOrderStatus(orderId, nextStatus);
                  ref.invalidate(ordersListProvider);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(nextIcon, color: color, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      nextLabel.toUpperCase(),
                      style: GoogleFonts.hankenGrotesk(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class ChefAssignmentDialog extends StatefulWidget {
  final String shortId;
  const ChefAssignmentDialog({super.key, required this.shortId});

  @override
  State<ChefAssignmentDialog> createState() => _ChefAssignmentDialogState();
}

class _ChefAssignmentDialogState extends State<ChefAssignmentDialog> {
  late TextEditingController _nameController;
  late TextEditingController _hoursController;
  late TextEditingController _minutesController;
  late TextEditingController _secondsController;
  int _activeQuickIdx = 4;

  final List<String> _quickChefs = ['Chef Hassan', 'Chef Afaq', 'Chef Ali', 'Chef Ayesha'];

  final List<Map<String, dynamic>> _quickDurations = [
    {'label': '30 Sec', 'h': 0, 'min': 0, 'sec': 30},
    {'label': '1 Min', 'h': 0, 'min': 1, 'sec': 0},
    {'label': '5 Min', 'h': 0, 'min': 5, 'sec': 0},
    {'label': '15 Min', 'h': 0, 'min': 15, 'sec': 0},
    {'label': '30 Min', 'h': 0, 'min': 30, 'sec': 0},
    {'label': '1 Hour', 'h': 1, 'min': 0, 'sec': 0},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Chef Hassan');
    _hoursController = TextEditingController(text: '0');
    _minutesController = TextEditingController(text: '5');
    _secondsController = TextEditingController(text: '00');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2035),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.outdoor_grill_rounded, color: Color(0xFF3498DB), size: 24),
              const SizedBox(width: 10),
              Text(
                'Assign Chef & Set Timer',
                style: GoogleFonts.ebGaramond(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Order #${widget.shortId} status will transition to PREPARING.',
            style: GoogleFonts.hankenGrotesk(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 20),
          
          // Chef Name Input
          TextField(
            controller: _nameController,
            style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              labelText: 'CHEF NAME',
              labelStyle: GoogleFonts.hankenGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
              hintText: 'Enter Chef Name',
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF3498DB)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          
          // Quick Chef Chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickChefs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final chef = _quickChefs[idx];
                final isSel = _nameController.text == chef;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _nameController.text = chef;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF3498DB) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      chef,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          
          // Quick Durations Selector
          Text(
            'QUICK DURATION',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickDurations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final dur = _quickDurations[idx];
                final isSel = _activeQuickIdx == idx;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeQuickIdx = idx;
                      _hoursController.text = dur['h'].toString();
                      _minutesController.text = dur['min'].toString();
                      _secondsController.text = dur['sec'].toString().padLeft(2, '0');
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF3498DB) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      dur['label'] as String,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            'CUSTOM TIME (HOURS • MINUTES • SECONDS)',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hoursController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  onChanged: (_) => setState(() => _activeQuickIdx = -1),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    labelText: 'HOURS',
                    labelStyle: GoogleFonts.hankenGrotesk(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3498DB))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  cursorColor: Colors.white,
                  onChanged: (val) {
                    setState(() {
                      _activeQuickIdx = -1; // Deselect quick chips if manually editing
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    labelText: 'MINUTES',
                    labelStyle: GoogleFonts.hankenGrotesk(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54),
                    suffixText: 'min',
                    suffixStyle: const TextStyle(color: Colors.white38),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3498DB)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Seconds box
              Expanded(
                child: TextField(
                  controller: _secondsController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  cursorColor: Colors.white,
                  onChanged: (val) {
                    setState(() {
                      _activeQuickIdx = -1; // Deselect quick chips if manually editing
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    labelText: 'SECONDS',
                    labelStyle: GoogleFonts.hankenGrotesk(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54),
                    suffixText: 'sec',
                    suffixStyle: const TextStyle(color: Colors.white38),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3498DB)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Confirm / Cancel Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final hours = int.tryParse(_hoursController.text) ?? 0;
                    final mins = int.tryParse(_minutesController.text) ?? 0;
                    final secs = int.tryParse(_secondsController.text) ?? 0;
                    if (hours == 0 && mins == 0 && secs == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please set a timer (hours, minutes, or seconds)')),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'chefName': _nameController.text.trim().isEmpty ? 'Chef Hassan' : _nameController.text.trim(),
                      'hours': hours,
                      'minutes': mins,
                      'seconds': secs,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Start Cooking', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
