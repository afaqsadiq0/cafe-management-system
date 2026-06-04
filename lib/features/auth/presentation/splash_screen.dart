import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/animated_typewriter_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Cup slides from top and settles
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final session = SupabaseConfig.client.auth.currentSession;
    
    if (mounted) {
      if (session != null) {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6F4E37), // Coffee brown
              const Color(0xFF8B4513), // Saddle brown
              const Color(0xFF3E2723), // Dark brown
            ],
          ),
        ),
        child: Stack(
          children: [
            // Coffee Beans Background Pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.network(
                  'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?q=80&w=2000', // Coffee beans
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const NetworkImage('https://images.unsplash.com/photo-1447933601403-0c6688de566e?q=80&w=2000'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.3),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Coffee Cup Icon
                  SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          border: Border.all(
                            color: const Color(0xFFD4AF37), // Gold
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.4),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_logo_round.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // App Name with Fade
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'MY CAFE',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 2,
                          width: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFFD4AF37),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Tagline with Typewriter
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedTypewriterText(
                      text: 'PREMIUM • QUALITY • EXPERIENCE',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFFD4AF37).withOpacity(0.8),
                        letterSpacing: 3,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      speed: const Duration(milliseconds: 60),
                      enableSound: true,
                    ),
                  ),
                ],
              ),
            ),
            
            // Loading Indicator
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: SizedBox(
                    width: 60,
                    height: 3,
                    child: LinearProgressIndicator(
                      color: const Color(0xFFD4AF37),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            
            // Version
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Text(
                    'Version 1.0.0',
                    style: GoogleFonts.montserrat(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

