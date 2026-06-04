import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/providers/repository_providers.dart';
import '../../orders/domain/orders_providers.dart';
import '../../auth/domain/auth_providers.dart';
import '../../../core/animations/staggered_fade_in.dart';
import '../../../core/animations/spring_scale_button.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/animated_typewriter_text.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      final hadSession = previous?.value?.session != null;
      final hasSession = next.value?.session != null;
      if (hasSession && !hadSession) {
        ref.invalidate(ordersListProvider);
      }
    });

    final ordersAsync = ref.watch(ordersListProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final isAdmin = userProfile?['role'] == 'admin';
    
    // Theme-aware colors
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final bgColor = isDark ? AppTheme.darkBgColor : AppTheme.secondaryColor;
    final textColor = isDark ? AppTheme.darkPrimaryText : AppTheme.primaryColor;
    final subtitleColor = isDark ? AppTheme.darkSecondaryText : AppTheme.onSurfaceVariant.withOpacity(0.7);
    final cardColor = isDark ? AppTheme.darkCardColor : Colors.white;
    final accentGold = isDark ? AppTheme.darkAccentColor : AppTheme.accentColor;

    return AnimatedTheme(
      data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          ordersAsync.when(
            loading: () => CustomScrollView(
              controller: _scrollController,
              slivers: _buildDashboardSlivers(
                [],
                textColor,
                subtitleColor,
                cardColor,
                accentGold,
                isDark,
                userProfile,
                isLoading: true,
              ),
            ),
            error: (err, _) => CustomScrollView(
              controller: _scrollController,
              slivers: _buildDashboardSlivers(
                [],
                textColor,
                subtitleColor,
                cardColor,
                accentGold,
                isDark,
                userProfile,
                loadError: err.toString(),
              ),
            ),
            data: (orders) => CustomScrollView(
              controller: _scrollController,
              slivers: _buildDashboardSlivers(
                orders,
                textColor,
                subtitleColor,
                cardColor,
                accentGold,
                isDark,
                userProfile,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  List<Widget> _buildDashboardSlivers(
    List<Map<String, dynamic>> orders,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
    Color accentGold,
    bool isDark,
    Map<String, dynamic>? userProfile, {
    bool isLoading = false,
    String? loadError,
  }) {
    return [
                  // Artisanal Custom Sliver AppBar
                  SliverAppBar(
                    expandedHeight: 140.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: isDark ? AppTheme.darkBgColor : AppTheme.secondaryColor,
                    elevation: 0,
                    leadingWidth: 80,
                    leading: Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: accentGold.withOpacity(0.5), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: accentGold.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
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
                    actions: [
                      IconButton(
                        icon: Icon(Icons.notifications_none_rounded, color: textColor),
                        onPressed: () {
                          final notifier = OrderNotificationService(SupabaseConfig.client);
                          notifier.simulateNewOrderNotification(context);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16, left: 8),
                        child: GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: accentGold, width: 2),
                            ),
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundImage: AssetImage('assets/images/profile_afaq.png'),
                            ),
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                      centerTitle: false,
                      title: Text(
                        'MY CAFE Control',
                        style: GoogleFonts.ebGaramond(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting Section with Typewriter Sound
                          AnimatedTypewriterText(
                            text: '${_getGreeting()}, ${userProfile?['full_name']?.split(' ')[0] ?? 'Admin'} ☕',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            speed: const Duration(milliseconds: 80),
                            enableSound: true,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Welcome to your digital vault. Manage your craft with precision.",
                            style: GoogleFonts.hankenGrotesk(
                              color: subtitleColor,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Live Revenue Stats ─────────────────────────────
                          _buildLiveStatsRow(orders, isDark, accentGold, cardColor, textColor, subtitleColor),

                          const SizedBox(height: 40),

                          // Executive Controls
                          Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: accentGold, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'EXECUTIVE CONTROLS',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildQuickActionButton(context, 'New Order', Icons.add_rounded, isDark ? accentGold : AppTheme.primaryColor, true, () => context.push('/new-order'), isDark),
                                const SizedBox(width: 16),
                                _buildQuickActionButton(context, 'Floor Plan', Icons.table_restaurant_rounded, cardColor, false, () => context.push('/tables'), isDark),
                                const SizedBox(width: 16),
                                _buildQuickActionButton(context, 'Kitchen', Icons.outdoor_grill_rounded, cardColor, false, () => context.push('/kds'), isDark),
                                const SizedBox(width: 16),
                                _buildQuickActionButton(context, 'Add Item', Icons.restaurant_menu_rounded, cardColor, false, () => context.go('/menu/add'), isDark),
                                const SizedBox(width: 16),
                                _buildQuickActionButton(context, 'Intelligence', Icons.insights_rounded, cardColor, false, () => context.push('/analytics'), isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Activity Canvas
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? accentGold : AppTheme.primaryColor).withOpacity(0.04),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Activity Canvas',
                                        style: GoogleFonts.ebGaramond(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => context.go('/orders'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: accentGold.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'View All',
                                          style: GoogleFonts.hankenGrotesk(
                                            color: accentGold,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                if (isLoading)
                                  const CardSkeletonList(count: 3, itemHeight: 80)
                                else if (loadError != null)
                                  _buildOrdersErrorPlaceholder(loadError, textColor, subtitleColor)
                                else if (orders.isEmpty)
                                  _buildEmptyOrdersPlaceholder(textColor, subtitleColor)
                                else
                                  _buildOrdersList(orders, textColor, subtitleColor),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ];
  }

  Widget _buildLiveStatsRow(
    List<Map<String, dynamic>> orders,
    bool isDark,
    Color accentGold,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    // Calculate today's stats from real orders
    final now = DateTime.now();
    double todayRevenue = 0;
    int todayOrders = 0;
    int pendingCount = 0;

    for (final order in orders) {
      final status = (order['status'] ?? '').toString().toLowerCase();
      if (status == 'cancelled') continue;

      // Count pending
      if (status == 'pending' || status == 'preparing') pendingCount++;

      // Today's revenue
      try {
        final createdAt = order['created_at']?.toString();
        if (createdAt != null) {
          final dt = DateTime.parse(createdAt).toLocal();
          if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
            todayRevenue += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
            todayOrders++;
          }
        }
      } catch (_) {}
    }

    final avgTicket = todayOrders > 0 ? todayRevenue / todayOrders : 0.0;

    final stats = [
      {
        'label': "TODAY'S REVENUE",
        'value': 'PKR ${todayRevenue.toStringAsFixed(0)}',
        'icon': Icons.payments_rounded,
        'color': const Color(0xFF27AE60),
        'sub': '$todayOrders orders today',
      },
      {
        'label': 'AVG TICKET',
        'value': 'PKR ${avgTicket.toStringAsFixed(0)}',
        'icon': Icons.analytics_rounded,
        'color': const Color(0xFF3498DB),
        'sub': 'Per order average',
      },
      {
        'label': 'ACTIVE ORDERS',
        'value': '$pendingCount',
        'icon': Icons.pending_actions_rounded,
        'color': pendingCount > 0 ? const Color(0xFFE67E22) : const Color(0xFF95A5A6),
        'sub': pendingCount > 0 ? 'Needs attention!' : 'All clear',
      },
      {
        'label': 'TOTAL ORDERS',
        'value': '${orders.length}',
        'icon': Icons.receipt_long_rounded,
        'color': accentGold,
        'sub': 'All time',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt_rounded, color: accentGold, size: 16),
            const SizedBox(width: 6),
            Text(
              'LIVE STATS',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: subtitleColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF27AE60),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: stats.map((s) => _buildLiveStatCard(
            label: s['label'] as String,
            value: s['value'] as String,
            icon: s['icon'] as IconData,
            color: s['color'] as Color,
            sub: s['sub'] as String,
            cardColor: cardColor,
            textColor: textColor,
            subtitleColor: subtitleColor,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildLiveStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String sub,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const Spacer(),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.ebGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: subtitleColor,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 9,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? trend, String? subtext, bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert ? AppTheme.accentColor.withOpacity(0.5) : AppTheme.primaryColor.withOpacity(0.05),
          width: isAlert ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Use spaceBetween instead of Spacer
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              if (isAlert) 
                const Icon(Icons.priority_high, color: Colors.red, size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox( // Prevent text overflow
                fit: BoxFit.scaleDown,
                child: Text(value, style: GoogleFonts.ebGaramond(fontSize: 26, fontWeight: FontWeight.bold, color: isAlert ? AppTheme.accentColor : AppTheme.primaryColor)),
              ),
              Text(title, style: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          if (trend != null || subtext != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trend != null)
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.green, size: 12),
                      const SizedBox(width: 4),
                      Text('$trend vs yesterday', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                if (subtext != null)
                  Text(subtext, style: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.6), fontSize: 9)),
              ],
            ),
        ],
      ),
    );
  }


  Widget _buildQuickActionButton(BuildContext context, String label, IconData icon, Color bgColor, bool isPrimary, VoidCallback onTap, bool isDark) {
    final theme = Theme.of(context);
    return SpringScaleButton(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: isPrimary 
            ? Border(bottom: BorderSide(color: isDark ? AppTheme.darkAccentColor : AppTheme.secondaryColor, width: 2))
            : Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: (isDark ? AppTheme.darkAccentColor : theme.colorScheme.primary).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isPrimary ? (isDark ? Colors.black : Colors.white) : theme.colorScheme.onSurface, size: 20),
            const SizedBox(width: 8),
            Text(
              label, 
              style: TextStyle(
                color: isPrimary ? (isDark ? Colors.black : Colors.white) : theme.colorScheme.onSurface, 
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, Color textColor, Color subtitleColor) {
    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length > 5 ? 5 : orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 20.0,
              child: FadeInAnimation(
                child: _buildOrderRow(order, textColor, subtitleColor),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersErrorPlaceholder(String error, Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 36, color: subtitleColor.withOpacity(0.6)),
          const SizedBox(height: 8),
          Text(
            'Could not load orders',
            style: GoogleFonts.hankenGrotesk(color: subtitleColor, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => ref.invalidate(ordersListProvider),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersPlaceholder(Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 40, color: subtitleColor.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'No orders yet',
              style: GoogleFonts.hankenGrotesk(
                color: subtitleColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.invalidate(ordersListProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order, Color textColor, Color subtitleColor) {
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final orderId = order['id']?.toString() ?? '';
    final orderLabel = order['order_number'] != null
        ? 'ORD-${order['order_number']}'
        : (orderId.length > 8 ? 'ORD-${orderId.substring(0, 8).toUpperCase()}' : 'ORD-$orderId');

    Color statusColor = const Color(0xFFD4AF37);
    if (status == 'preparing') statusColor = const Color(0xFF3498DB);
    if (status == 'completed' || status == 'done') statusColor = const Color(0xFF519259);
    if (status == 'cancelled' || status == 'canceled') statusColor = const Color(0xFFC0392B);

    final statusLabel = status.isNotEmpty
        ? '${status[0].toUpperCase()}${status.substring(1)}'
        : 'Pending';

    return InkWell(
      onTap: () {
        if (orderId.isNotEmpty) context.push('/orders/$orderId/receipt');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: textColor.withOpacity(0.03))),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 35,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    orderLabel,
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: textColor,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order['customer'] ?? 'Walk-in Guest',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'PKR ${(order['total_amount'] as num?)?.toStringAsFixed(0) ?? order['amount'] ?? '0'}',
                      style: GoogleFonts.ebGaramond(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel.toUpperCase(),
                      style: GoogleFonts.hankenGrotesk(
                        color: statusColor,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

