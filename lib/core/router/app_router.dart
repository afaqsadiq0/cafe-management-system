import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../animations/page_transitions.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/menu/presentation/add_edit_item_screen.dart';
import '../../features/orders/presentation/order_list_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/order_taking_screen.dart';
import '../../features/orders/presentation/receipt_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/dashboard/presentation/main_shell.dart';
import '../../features/tables/presentation/table_management_screen.dart';
import '../../features/kds/presentation/kds_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => AppPageTransitions.sharedAxis(
          child: const LoginScreen(),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => AppPageTransitions.slideFade(
          child: const SignupScreen(),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => AppPageTransitions.slideFade(
          child: const ForgotPasswordScreen(),
          key: state.pageKey,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (context, state) => AppPageTransitions.sharedAxis(
                  child: const DashboardScreen(),
                  key: state.pageKey,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/menu',
                pageBuilder: (context, state) => AppPageTransitions.sharedAxis(
                  child: const MenuScreen(),
                  key: state.pageKey,
                ),
                routes: [
                  GoRoute(
                    path: 'add',
                    pageBuilder: (context, state) => AppPageTransitions.slideFade(
                      child: const AddEditItemScreen(),
                      key: state.pageKey,
                    ),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AppPageTransitions.slideFade(
                        child: AddEditItemScreen(itemId: id),
                        key: state.pageKey,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const OrderListScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (context, state) => AppPageTransitions.slideFade(
                      child: const OrderTakingScreen(),
                      key: state.pageKey,
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AppPageTransitions.slideFade(
                        child: OrderDetailScreen(orderId: id),
                        key: state.pageKey,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'receipt',
                        pageBuilder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return AppPageTransitions.scaleUp(
                            child: ReceiptScreen(orderId: id),
                            key: state.pageKey,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                pageBuilder: (context, state) => AppPageTransitions.sharedAxis(
                  child: const AnalyticsScreen(),
                  key: state.pageKey,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => AppPageTransitions.sharedAxis(
                  child: const ProfileScreen(),
                  key: state.pageKey,
                ),
              ),
            ],
          ),
        ],
      ),
      // ── Standalone screens (outside StatefulShellRoute) ───────────
      GoRoute(
        path: '/tables',
        pageBuilder: (context, state) => AppPageTransitions.slideFade(
          child: const TableManagementScreen(),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/kds',
        pageBuilder: (context, state) => AppPageTransitions.slideFade(
          child: const KdsScreen(),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/new-order',
        pageBuilder: (context, state) {
          final customerName = state.uri.queryParameters['customerName'];
          return AppPageTransitions.slideFade(
            child: OrderTakingScreen(prefilledCustomerName: customerName),
            key: state.pageKey,
          );
        },
      ),
    ],
  );
});
