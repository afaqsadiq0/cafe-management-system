import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/providers/repository_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  runApp(
    const ProviderScope(
      child: MyCafeApp(),
    ),
  );
}

class MyCafeApp extends ConsumerStatefulWidget {
  const MyCafeApp({super.key});

  @override
  ConsumerState<MyCafeApp> createState() => _MyCafeAppState();
}

class _MyCafeAppState extends ConsumerState<MyCafeApp> {
  @override
  void initState() {
    super.initState();
    // Start background sync service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).start(context);
      ref.read(orderNotificationServiceProvider).listenToOrderChanges(context);
    });
  }


  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'MY Cafe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => _MobileFrame(child: child),
    );
  }
}

class _MobileFrame extends StatelessWidget {
  final Widget? child;
  const _MobileFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    if (!isWeb) {
      // Mobile: full screen as normal
      return child ?? const SizedBox.shrink();
    }

    // Web/Desktop: centered mobile frame
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Container(
          width: 390,
          height: 844,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 60,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.3),
                blurRadius: 80,
                spreadRadius: -10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(48),
            child: Stack(
              children: [
                // App content
                child ?? const SizedBox.shrink(),
                // Phone top notch overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(48)),
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 6,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
