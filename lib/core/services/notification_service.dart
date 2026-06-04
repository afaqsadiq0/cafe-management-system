import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../theme/app_theme.dart';

class OrderNotificationService {
  final SupabaseClient _supabase;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  OrderNotificationService(this._supabase) {
    initLocalNotifications();
  }

  Future<void> initLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Local Notification clicked: ${details.payload}');
        },
      );
      
      final androidPlugin = _localNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Failed to initialize local notifications: $e');
    }
  }

  Future<void> showNativeNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'cafe_orders_channel',
        'Cafe Order Notifications',
        channelDescription: 'Notifications for Cafe Orders and Updates',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotificationsPlugin.show(
        Random().nextInt(100000), // Random ID to prevent overlap
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint('Error showing native status-bar notification: $e');
    }
  }

  void listenToOrderChanges(BuildContext context) {
    _supabase
        .channel('order_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            final newStatus = payload.newRecord['status'];
            final orderId = payload.newRecord['id'];
            final shortId = orderId != null && orderId.toString().length > 8
                ? orderId.toString().substring(0, 8).toUpperCase()
                : (orderId?.toString() ?? 'UNKNOWN');
            
            if (newStatus != null) {
              final statusMsg = 'Order #$shortId status is now: $newStatus!';
              _showNotification(context, statusMsg, _getStatusColor(newStatus));
              _playSound();
              
              // Trigger native mobile status bar notification
              showNativeNotification(
                '🔔 Order Update',
                statusMsg,
              );
            }
          },
        )
        .subscribe();
  }

  /// Kitchen timer finished — works even when app is in background.
  Future<void> notifyKitchenReady(String orderId, String chefName) async {
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId;
    final body = 'Order #$shortId by $chefName is READY to serve! 🍽️';
    await showNativeNotification('🍳 Kitchen — Order Ready!', body);
    await _playSound();
    debugPrint('Kitchen ready notification sent: $body');
  }

  Future<void> notifyOrderStatusChange(String orderId, String status) async {
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId;
    final normalized = status.toLowerCase();
    String title;
    String body;
    switch (normalized) {
      case 'preparing':
        title = '👨‍🍳 Order Preparing';
        body = 'Order #$shortId is now being prepared in the kitchen.';
        break;
      case 'completed':
      case 'done':
        title = '✅ Order Completed';
        body = 'Order #$shortId is completed and ready!';
        break;
      case 'cancelled':
      case 'canceled':
        title = '❌ Order Cancelled';
        body = 'Order #$shortId has been cancelled.';
        break;
      default:
        title = '🔔 Order Update';
        body = 'Order #$shortId status: $status';
    }
    await showNativeNotification(title, body);
    await _playSound();
  }

  void triggerStatusNotification(BuildContext context, String orderId, String newStatus) {
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId;
    
    // Check if newStatus is already a full ready message or just status
    final String displayMsg = newStatus.contains('Ready') || newStatus.contains('Prepared')
        ? newStatus
        : 'Order #$shortId status updated to $newStatus!';
        
    _showNotification(context, displayMsg, _getStatusColor(newStatus));
    _playSound();
    
    notifyOrderStatusChange(orderId, newStatus);
  }

  void simulateNewOrderNotification(BuildContext context) {
    final randomOrderNum = 1000 + Random().nextInt(9000);
    final msg = '🔔 New Order Received! (#$randomOrderNum)';
    _showNotification(context, msg, AppTheme.secondaryColor);
    _playSound();
    
    // Trigger native mobile status bar notification
    showNativeNotification(
      '☕ New Order!',
      msg,
    );
  }

  void _showNotification(BuildContext context, String message, Color bgColor) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return TopNotificationBanner(
          message: message,
          bgColor: bgColor,
          onDismiss: () {
            overlayEntry.remove();
          },
        );
      },
    );

    overlay.insert(overlayEntry);
  }

  Future<void> _playSound() async {
    try {
      // Use a built-in sound URL or local asset if available. Here we play a standard notification tone URL.
      // Alternatively, can use SystemSound, but audioplayers allows custom sounds.
      await _audioPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/beep_short.ogg'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'preparing': return Colors.blue;
      case 'ready': return Colors.teal;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.amber;
    }
  }
}

class TopNotificationBanner extends StatefulWidget {
  final String message;
  final Color bgColor;
  final VoidCallback onDismiss;

  const TopNotificationBanner({
    super.key,
    required this.message,
    required this.bgColor,
    required this.onDismiss,
  });

  @override
  State<TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<TopNotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Dismissible(
            key: const Key('top_notification_banner'),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2035),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.bgColor.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.bgColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_active_rounded, color: widget.bgColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔔 CAFE NOTIFICATION',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: widget.bgColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                      onPressed: _dismiss,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
