import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/repository_providers.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  Timer? _tickerTimer;
  String? _chefName;
  DateTime? _targetTime;

  @override
  void initState() {
    super.initState();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
    Future.microtask(() {
      _loadOrderDetails();
      _loadChefAndTimer();
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final order = await orderRepo.getOrder(widget.orderId);
      final items = await orderRepo.getOrderItems(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _items = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadChefAndTimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _chefName = prefs.getString('chef_${widget.orderId}');
        final timerStr = prefs.getString('timer_${widget.orderId}');
        if (timerStr != null) {
          _targetTime = DateTime.parse(timerStr);
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Order...')),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
          ),
        ),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Order details not found', style: GoogleFonts.ebGaramond(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/orders'),
                child: const Text('View All Orders'),
              ),
            ],
          ),
        ),
      );
    }

    final orderId = _order!['id'] as String;
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId;
    final status = (_order!['status'] ?? 'pending').toString().toLowerCase();
    
    // Parse times
    String timeStr = '--';
    if (_order!['created_at'] != null) {
      try {
        final dt = DateTime.parse(_order!['created_at'].toString()).toLocal();
        final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        final min = dt.minute.toString().padLeft(2, '0');
        timeStr = '$hour:$min $period';
      } catch (_) {}
    }

    final subtotal = (_order!['subtotal'] as num?)?.toDouble() ?? 0.0;
    final tax = (_order!['tax_amount'] as num?)?.toDouble() ?? 0.0;
    final total = (_order!['total_amount'] as num?)?.toDouble() ?? 0.0;
    final notes = _order!['notes']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$shortId', style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () => context.push('/orders/$orderId/receipt'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Timeline
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusStep('Placed', true, timeStr),
                        _buildConnector(status == 'preparing' || status == 'ready' || status == 'completed' || status == 'done'),
                        _buildStatusStep('Preparing', status == 'preparing' || status == 'ready' || status == 'completed' || status == 'done', status == 'preparing' ? 'In progress' : '--'),
                        _buildConnector(status == 'ready' || status == 'completed' || status == 'done'),
                        _buildStatusStep('Ready', status == 'ready' || status == 'completed' || status == 'done', status == 'ready' ? 'Finished' : '--'),
                        _buildConnector(status == 'completed' || status == 'done'),
                        _buildStatusStep('Completed', status == 'completed' || status == 'done', status == 'completed' || status == 'done' ? 'Served' : '--'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live Countdown Cooking Banner
            if (status == 'preparing' || status == 'ready') ...[
              _buildLiveCountdownBanner(),
              const SizedBox(height: 16),
            ],
            
            // Order Items Summary
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.restaurant_menu_rounded, color: AppTheme.secondaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text('Order Details', style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const Divider(height: 24),
                    
                    if (_items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('No items listed in this order.', style: TextStyle(color: Colors.grey[500])),
                      )
                    else
                      ..._items.map((item) => _buildItemRow(
                            item['item_name'] ?? 'Item',
                            (item['quantity'] ?? 1).toString(),
                            (item['item_price'] ?? 0.0).toStringAsFixed(1),
                          )),
                          
                    if (notes.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text('Customer Name / Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(notes, style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],

                    const Divider(height: 24),
                    _buildSummaryRow('Subtotal', subtotal.toStringAsFixed(1)),
                    _buildSummaryRow('VAT (Included)', tax.toStringAsFixed(1)),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Total Amount', total.toStringAsFixed(1), isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/orders/$orderId/receipt'),
                    icon: const Icon(Icons.receipt_long, color: Colors.white),
                    label: const Text('VIEW RECEIPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCountdownBanner() {
    final chef = _chefName ?? 'Chef Hassan';
    final status = _order?['status']?.toString().toLowerCase() ?? '';
    final dbReady = status == 'ready';
    
    String countdown = '--:--';
    bool isReady = dbReady;
    
    if (!dbReady && _targetTime != null) {
      final diff = _targetTime!.difference(DateTime.now());
      if (diff.isNegative) {
        countdown = 'READY 🔔';
        isReady = true;
      } else {
        final mins = diff.inMinutes.toString().padLeft(2, '0');
        final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
        countdown = '$mins:$secs';
      }
    } else if (dbReady) {
      countdown = 'READY 🔔';
    }
    
    final bannerColor = isReady ? const Color(0xFF27AE60) : const Color(0xFF3498DB);
    
    return Card(
      color: bannerColor.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: bannerColor.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bannerColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.outdoor_grill, color: bannerColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isReady ? 'PREPARATION COMPLETED' : 'KITCHEN PREPARATION ACTIVE',
                    style: GoogleFonts.hankenGrotesk(fontSize: 10, fontWeight: FontWeight.w800, color: bannerColor, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chef in charge: $chef',
                    style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bannerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(isReady ? Icons.notifications_active : Icons.timer, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    countdown,
                    style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep(String label, bool isCompleted, String time) {
    return Column(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? AppTheme.secondaryColor : Colors.grey[300],
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal)),
        Text(time, style: TextStyle(fontSize: 8, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildConnector(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? AppTheme.secondaryColor : Colors.grey[200],
      ),
    );
  }

  Widget _buildItemRow(String name, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            'x$qty ',
            style: GoogleFonts.hankenGrotesk(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          Text(
            'PKR $price',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            'PKR $value',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? AppTheme.secondaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
