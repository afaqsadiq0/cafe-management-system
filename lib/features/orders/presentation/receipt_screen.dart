import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/repository_providers.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final String orderId;
  const ReceiptScreen({super.key, required this.orderId});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _unrollAnimation;
  double _totalAmount = 0.0;
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  Timer? _tickerTimer;
  String? _chefName;
  DateTime? _targetTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _unrollAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.forward();
    
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
  void dispose() {
    _tickerTimer?.cancel();
    _controller.dispose();
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
          _totalAmount = (order?['total_amount'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? createdAtStr) {
    if (createdAtStr == null) return 'Today';
    try {
      final dt = DateTime.parse(createdAtStr).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '15 May 2026';
    }
  }

  String _formatTime(String? createdAtStr) {
    if (createdAtStr == null) return '';
    try {
      final dt = DateTime.parse(createdAtStr).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min $period';
    } catch (_) {
      return '';
    }
  }

  Future<void> _printReceipt() async {
    if (_order == null) return;
    final pdf = pw.Document();
    
    // Add page with standard thermal receipt sizing (80mm width)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('Artisanal Cafe', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(
                child: pw.Text('PREMIUM COFFEE HOUSE', style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 5),
              pw.Text('Order: #${widget.orderId.substring(0, 8).toUpperCase()}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              if (_order!['notes'] != null && _order!['notes'].toString().isNotEmpty)
                pw.Text('Customer: ${_order!['notes']}', style: pw.TextStyle(fontSize: 8)),
              pw.Text('Date: ${_formatDate(_order!['created_at'])}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Time: ${_formatTime(_order!['created_at'])}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Server: ${_order!['staff_id'].length > 10 ? _order!['staff_id'].substring(0, 8) : _order!['staff_id']}', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),
              
              // Items List
              ..._items.map((item) {
                final name = item['item_name'] ?? 'Item';
                final qty = item['quantity'] ?? 1;
                final price = item['item_price'] ?? 0.0;
                final total = qty * price;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text('$name x$qty', style: const pw.TextStyle(fontSize: 8))),
                      pw.Text('PKR ${total.toStringAsFixed(1)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                );
              }),
              
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 5),
              _pdfSummaryRow('Subtotal', (_order!['subtotal'] ?? 0.0).toStringAsFixed(1)),
              _pdfSummaryRow('VAT (Included)', (_order!['tax_amount'] ?? 0.0).toStringAsFixed(1)),
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('PKR ${(_order!['total_amount'] ?? 0.0).toStringAsFixed(1)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('Thank you for your patronage', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Receipt_${widget.orderId.substring(0, 8).toUpperCase()}',
      );
    } catch (e) {
      debugPrint('Printing error: $e');
    }
  }

  pw.Widget _pdfSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text('PKR $value', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.background : const Color(0xFFEFEBE9),
      appBar: AppBar(
        title: Text('Order Receipt', style: GoogleFonts.ebGaramond()),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              ),
            )
          : _order == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.secondary),
                      const SizedBox(height: 16),
                      Text('Order receipt details not found', style: GoogleFonts.ebGaramond(fontSize: 18, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/orders'),
                        child: const Text('View All Orders'),
                      )
                    ],
                  ),
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      child: Column(
                        children: [
                          SizeTransition(
                            sizeFactor: _unrollAnimation,
                            axisAlignment: 1.0,
                            child: CustomPaint(
                              painter: ReceiptPainter(isDark: isDark, paperColor: isDark ? theme.colorScheme.surface : Colors.white),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    Icon(Icons.coffee_rounded, size: 48, color: theme.colorScheme.primary),
                                    const SizedBox(height: 8),
                                    Text('Artisanal Cafe', style: GoogleFonts.ebGaramond(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                    Text('PREMIUM COFFEE HOUSE', style: GoogleFonts.hankenGrotesk(fontSize: 10, letterSpacing: 2, color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                                    if (_order != null && (_order!['status'].toString().toLowerCase() == 'preparing' || _order!['status'].toString().toLowerCase() == 'ready')) ...[
                                      const SizedBox(height: 16),
                                      _buildLiveKitchenBanner(theme),
                                    ],
                                    const SizedBox(height: 24),
                                    Divider(color: theme.colorScheme.onSurface.withOpacity(0.1), thickness: 1),
                                    const SizedBox(height: 16),
                                    _receiptRow('Order Reference', '#${widget.orderId.substring(0, 8).toUpperCase()}', theme),
                                    if (_order!['notes'] != null && _order!['notes'].toString().isNotEmpty)
                                      _receiptRow('Customer', _order!['notes'].toString(), theme),
                                    _receiptRow('Date', _formatDate(_order!['created_at']), theme),
                                    _receiptRow('Time', _formatTime(_order!['created_at']), theme),
                                    _receiptRow('Server', _order!['staff_id'].length > 10 ? _order!['staff_id'].substring(0, 8) : _order!['staff_id'], theme),
                                    const SizedBox(height: 16),
                                    Divider(color: theme.colorScheme.onSurface.withOpacity(0.1), thickness: 1),
                                    const SizedBox(height: 24),
                                    
                                    // Live items rendering
                                    ..._items.map((item) => _receiptItem(
                                      item['item_name'] ?? 'Item',
                                      (item['quantity'] ?? 1).toString(),
                                      (item['item_price'] ?? 0.0).toString(),
                                      theme,
                                    )),
                                    
                                    const SizedBox(height: 24),
                                    Divider(color: theme.colorScheme.onSurface.withOpacity(0.1), thickness: 1, height: 1),
                                    const SizedBox(height: 16),
                                    _receiptSummary('Subtotal', (_order!['subtotal'] ?? 0.0).toStringAsFixed(1), theme),
                                    _receiptSummary('VAT (Included)', (_order!['tax_amount'] ?? 0.0).toStringAsFixed(1), theme),
                                    const SizedBox(height: 16),
                                    Divider(color: theme.colorScheme.onSurface, thickness: 1.5, height: 1),
                                    const SizedBox(height: 16),
                                    
                                    // Animated Total
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('GRAND TOTAL', style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1, color: theme.colorScheme.onSurface)),
                                        Row(
                                          children: [
                                            Text('PKR ', style: GoogleFonts.ebGaramond(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                                            AnimatedFlipCounter(
                                              value: _totalAmount,
                                              fractionDigits: 1,
                                              textStyle: GoogleFonts.ebGaramond(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 40),
                                    
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: QrImageView(
                                        data: widget.orderId,
                                        version: QrVersions.auto,
                                        size: 80.0,
                                        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: theme.colorScheme.primary),
                                        dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: theme.colorScheme.onSurface),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text('Thank you for your patronage', style: GoogleFonts.ebGaramond(fontStyle: FontStyle.italic, fontSize: 16, color: theme.colorScheme.onSurface)),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          FadeTransition(
                            opacity: _unrollAnimation,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _printReceipt,
                                    icon: const Icon(Icons.print_rounded, size: 20),
                                    label: const Text('PRINT'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Share.share('Order #${widget.orderId.length > 8 ? widget.orderId.substring(0, 8).toUpperCase() : widget.orderId} Receipt - PKR ${(_order!['total_amount'] ?? 0.0).toStringAsFixed(1)}');
                                    },
                                    icon: Icon(Icons.share_rounded, color: theme.colorScheme.primary, size: 20),
                                    label: Text('SHARE', style: TextStyle(color: theme.colorScheme.primary)),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: theme.colorScheme.primary),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      minimumSize: const Size(0, 54),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _unrollAnimation,
                            child: TextButton(
                              onPressed: () => context.go('/dashboard'),
                              child: Text('RETURN TO DASHBOARD', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    
                    // Confetti Overlay
                    IgnorePointer(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Lottie.network(
                          'https://assets9.lottiefiles.com/packages/lf20_u4yrau.json', 
                          repeat: false,
                          width: double.infinity,
                          height: 400,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _receiptRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.hankenGrotesk(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.hankenGrotesk(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptItem(String name, String qty, String price, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.ebGaramond(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text('Unit: PKR $price', style: GoogleFonts.hankenGrotesk(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('x$qty', style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
          const SizedBox(width: 24),
          Text(
            'PKR ${(double.parse(qty) * double.parse(price)).toStringAsFixed(1)}', 
            style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _receiptSummary(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.hankenGrotesk(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'PKR $value',
              style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveKitchenBanner(ThemeData theme) {
    final chef = _chefName ?? 'Chef Hassan';
    final statusLower = _order?['status']?.toString().toLowerCase() ?? '';
    final dbReady = statusLower == 'ready';
    
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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.outdoor_grill_rounded, color: bannerColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReady ? '🍳 PREPARATION COMPLETED' : '🍳 Kitchen preparing order',
                  style: GoogleFonts.hankenGrotesk(fontSize: 9, fontWeight: FontWeight.bold, color: bannerColor, letterSpacing: 0.5),
                ),
                Text(
                  'Chef: $chef',
                  style: GoogleFonts.hankenGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bannerColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isReady ? Icons.notifications_active : Icons.timer, color: Colors.white, size: 10),
                const SizedBox(width: 4),
                Text(
                  countdown,
                  style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiptPainter extends CustomPainter {
  final bool isDark;
  final Color paperColor;
  ReceiptPainter({required this.isDark, required this.paperColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = paperColor
      ..style = PaintingStyle.fill;

    final path = Path();
    const sawSize = 12.0;
    
    // Top serrated edge
    path.moveTo(0, 0);
    for (var i = 0; i < size.width / sawSize; i++) {
      path.relativeLineTo(sawSize / 2, sawSize / 3);
      path.relativeLineTo(sawSize / 2, -sawSize / 3);
    }
    
    path.lineTo(size.width, size.height);
    
    // Bottom serrated edge
    for (var i = 0; i < size.width / sawSize; i++) {
      path.relativeLineTo(-sawSize / 2, sawSize / 3);
      path.relativeLineTo(-sawSize / 2, -sawSize / 3);
    }
    
    path.lineTo(0, 0);
    path.close();
    
    canvas.drawShadow(path.shift(const Offset(0, 2)), Colors.black.withOpacity(isDark ? 0.4 : 0.1), 10, true);
    canvas.drawPath(path, paint);
    
    // Add subtle paper texture lines
    final linePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (var i = 1; i < 10; i++) {
       canvas.drawLine(Offset(0, size.height * (i/10)), Offset(size.width, size.height * (i/10)), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

