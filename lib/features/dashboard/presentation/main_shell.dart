import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../auth/domain/auth_providers.dart';
import '../../../core/theme/app_theme.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}
/// Maps bottom-nav index to StatefulShellRoute branch index.
int _branchIndexForNav(int navIndex, bool isAdmin) {
  if (isAdmin) return navIndex;
  // Non-admin: Home, Menu, Orders, Intelligence → branches 0,1,2,3 (analytics)
  if (navIndex <= 2) return navIndex;
  return 3; // Intelligence → analytics branch
}

class _MainShellState extends ConsumerState<MainShell> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      5, // Max items (3 + Admin Analytics + Intelligence)
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  void _triggerRipple(int index) {
    _controllers[index].forward(from: 0.0);
    _playWaterSound();
    HapticFeedback.selectionClick();
  }

  Future<void> _playWaterSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2571/2571-preview.mp3'), volume: 0.6);
    } catch (e) {
      debugPrint('Error playing water sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).value;
    final role = (userProfile?['role'] ?? '').toString().toLowerCase();
    final isAdmin = role == 'admin' || role == 'administrator';
    final currentIndex = widget.navigationShell.currentIndex;

    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.restaurant_menu_outlined),
        activeIcon: Icon(Icons.restaurant_menu),
        label: 'Menu',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long_outlined),
        activeIcon: Icon(Icons.receipt_long),
        label: 'Orders',
      ),
    ];

    if (isAdmin) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined),
        activeIcon: Icon(Icons.bar_chart),
        label: 'Analytics',
      ));
    }

    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.analytics_outlined),
      activeIcon: Icon(Icons.analytics),
      label: 'Intelligence',
    ));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        height: 95 + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 4, top: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.05))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          child: AnimationLimiter(
            key: const ValueKey('bottom_nav'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final branchIndex = _branchIndexForNav(index, isAdmin);
                final isSelected = currentIndex == branchIndex;
                final accentColor = isDark ? AppTheme.darkAccentColor : AppTheme.secondaryColor;
                
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    verticalOffset: 20.0,
                    curve: Curves.easeOutBack,
                    child: FadeInAnimation(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _triggerRipple(index);
                          final branchIndex = _branchIndexForNav(index, isAdmin);
                          widget.navigationShell.goBranch(
                            branchIndex,
                            initialLocation: true,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor.withOpacity(0.08) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Water Drop Ripple Animation
                                  AnimatedBuilder(
                                    animation: _controllers[index],
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: WaterDropPainter(
                                          progress: _controllers[index].value,
                                          color: accentColor.withOpacity(0.4),
                                        ),
                                        size: const Size(36, 36),
                                      );
                                    },
                                  ),
                                AnimatedScale(
                                  scale: isSelected ? 1.15 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.elasticOut,
                                  child: IconTheme(
                                    data: IconThemeData(
                                      color: isSelected ? accentColor : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                      size: 24,
                                    ),
                                    child: isSelected ? item.activeIcon : item.icon,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                (item.label ?? '').toUpperCase(),
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 9,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                  color: isSelected ? accentColor : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ),
  );
  }
}

class WaterDropPainter extends CustomPainter {
  final double progress;
  final Color color;

  WaterDropPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withOpacity((1 - progress) * 0.4)
      ..style = PaintingStyle.fill;

    // Drawing a 'liquid' expanding circle
    final radius = size.width * 0.8 * progress;
    
    // Slight oval distortion for 'liquid' feel
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * (1 + 0.1 * progress),
        height: radius * (1 - 0.1 * progress),
      ),
      paint,
    );

    // Outer ring ripple
    final ringPaint = Paint()
      ..color = color.withOpacity((1 - progress) * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius * 1.2, ringPaint);
  }

  @override
  bool shouldRepaint(covariant WaterDropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}


