import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_providers.dart';
import '../../../core/supabase/supabase_config.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedTextSize = 'Medium';

  static Widget _imageErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      color: const Color(0xFFFFF2EC),
      child: const Icon(Icons.person, size: 80, color: Color(0xFFB07B69)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProfile = ref.watch(userProfileProvider).value;
    
    // Dynamic colors based on theme
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurfaceVariant;
    final accentGold = isDark ? AppTheme.darkAccentColor : AppTheme.secondaryColor;
    final iconBgColor = accentGold.withOpacity(0.1);

    return AnimatedTheme(
      data: theme,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.menu, color: textColor),
            onPressed: () {},
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: const AssetImage('assets/images/profile_afaq.png'),
                backgroundColor: theme.colorScheme.surfaceVariant,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    // Gold Framed Square Profile
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: accentGold, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Image.asset(
                              'assets/images/profile_afaq.png',
                              fit: BoxFit.cover,
                              errorBuilder: _imageErrorBuilder,
                            ),
                          ),
                        ),
                        Container(
                          transform: Matrix4.translationValues(5, 5, 0),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentGold,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                            ],
                          ),
                          child: Icon(Icons.edit_rounded, color: isDark ? Colors.black : Colors.white, size: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'AFAQ GUJJAR',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentGold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: accentGold, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            'SENIOR MANAGER',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: accentGold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 48),

            // Settings Section Header
            _buildSectionHeader('Preferences', theme),
            const SizedBox(height: 16),
            
            // Settings Card 1
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _buildCustomTile(
                    icon: Icons.dark_mode_outlined,
                    iconBg: iconBgColor,
                    iconColor: accentGold,
                    title: 'Dark Mode',
                    titleColor: textColor,
                    subtitle: 'Switch to the dark luxury theme',
                    subtitleColor: subtitleColor,
                    trailing: Switch(
                      value: isDark,
                      activeColor: accentGold,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ),
                  _buildDivider(theme),
                  _buildCustomTile(
                    icon: Icons.notifications_none_rounded,
                    iconBg: iconBgColor,
                    iconColor: accentGold,
                    title: 'Notifications',
                    titleColor: textColor,
                    subtitle: 'Manage alerts and sound signals',
                    subtitleColor: subtitleColor,
                    trailing: Switch(
                      value: _notificationsEnabled,
                      activeColor: accentGold,
                      onChanged: (val) => setState(() => _notificationsEnabled = val),
                    ),
                  ),
                  _buildDivider(theme),
                  _buildCustomTile(
                    icon: Icons.text_fields_rounded,
                    iconBg: iconBgColor,
                    iconColor: accentGold,
                    title: 'Text Style',
                    titleColor: textColor,
                    subtitle: 'Adjust font size for readability',
                    subtitleColor: subtitleColor,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _selectedTextSize,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    onTap: () => _showOptionsDialog(context, 'Select Text Size', ['Small', 'Medium', 'Large', 'Extra Large'], (value) {
                      setState(() => _selectedTextSize = value);
                    }, isDark, textColor, cardColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('Account & Security', theme),
            const SizedBox(height: 16),
            
            // Settings Card 2
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _buildCustomTile(
                    icon: Icons.lock_outline_rounded,
                    iconBg: iconBgColor,
                    iconColor: accentGold,
                    title: 'Security',
                    titleColor: textColor,
                    subtitle: 'Update your security credentials',
                    subtitleColor: subtitleColor,
                    onTap: () => _showSecurityDialog(context, isDark, textColor, cardColor, accentGold),
                  ),
                  _buildDivider(theme),
                  _buildCustomTile(
                    icon: Icons.security_rounded,
                    iconBg: iconBgColor,
                    iconColor: accentGold,
                    title: 'Privacy',
                    titleColor: textColor,
                    subtitle: 'Manage your data and privacy settings',
                    subtitleColor: subtitleColor,
                    onTap: () => _showPrivacyDialog(context, isDark, textColor, cardColor, accentGold),
                  ),
                  _buildDivider(theme),
                  _buildCustomTile(
                    icon: Icons.info_outline_rounded,
                    iconBg: iconBgColor,
                    iconColor: accentGold,
                    title: 'About',
                    titleColor: textColor,
                    subtitle: 'Terms, policies and version info',
                    subtitleColor: subtitleColor,
                    onTap: () => _showAboutDialog(context, isDark, textColor, cardColor, accentGold),
                  ),
                  _buildDivider(theme),
                  _buildCustomTile(
                    icon: Icons.logout_rounded,
                    iconBg: theme.colorScheme.error.withOpacity(0.1),
                    iconColor: theme.colorScheme.error,
                    title: 'Logout',
                    titleColor: theme.colorScheme.error,
                    subtitle: 'Sign out of your session',
                    subtitleColor: subtitleColor,
                    onTap: () async {
                      final confirm = await _showLogoutConfirmDialog(context, isDark, textColor, cardColor);
                      if (confirm == true) {
                        await SupabaseConfig.client.auth.signOut();
                        if (mounted) context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),
            
            // Footer Branding
            Text(
              'ARTISANAL PRECISION SOFTWARE',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PRO v1.2.0',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, String title, List<String> options, Function(String) onSelect, bool isDark, Color textColor, Color cardColor) {
    final accentGold = isDark ? AppTheme.darkAccentColor : AppTheme.secondaryColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold, color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((e) => ListTile(
            title: Text(e, style: GoogleFonts.hankenGrotesk(color: textColor)),
            onTap: () {
              onSelect(e);
              context.pop();
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('CLOSE', style: GoogleFonts.hankenGrotesk(color: accentGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context, bool isDark, Color textColor, Color cardColor, Color accentGold) {
    final subtitleColor = isDark ? AppTheme.darkSecondaryText : Colors.grey[700]!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.security, color: accentGold),
            const SizedBox(width: 12),
            Text('Privacy Settings', style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Protection',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your personal information is encrypted and stored securely. We follow industry-standard security practices to protect your data.',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  height: 1.6,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Data Usage',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Profile information for authentication\n• Activity logs for audit purposes\n• Performance metrics for analytics\n• No data shared with third parties',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  height: 1.6,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('UNDERSTOOD', style: GoogleFonts.hankenGrotesk(color: accentGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context, bool isDark, Color textColor, Color cardColor, Color accentGold) {
    final subtitleColor = isDark ? AppTheme.darkSecondaryText : Colors.grey[700]!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_person_rounded, color: accentGold),
            const SizedBox(width: 12),
            Text('Security Settings', style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Authentication',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Two-factor authentication is active for your account. You will receive a code via email for new logins.',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  height: 1.6,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Recent Activity',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              _buildSecurityActivityItem('Logged in from Android 14', '2 hours ago', isDark, textColor, subtitleColor),
              _buildSecurityActivityItem('Password changed', '3 days ago', isDark, textColor, subtitleColor),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGold,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('CHANGE PASSWORD', style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('CLOSE', style: GoogleFonts.hankenGrotesk(color: accentGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityActivityItem(String activity, String time, bool isDark, Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activity,
              style: GoogleFonts.hankenGrotesk(fontSize: 13, color: textColor),
            ),
          ),
          Text(
            time,
            style: GoogleFonts.hankenGrotesk(fontSize: 11, color: subtitleColor),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, bool isDark, Color textColor, Color cardColor, Color accentGold) {
    final subtitleColor = isDark ? AppTheme.darkSecondaryText : Colors.grey[700]!;
    final iconBgColor = accentGold.withOpacity(0.1);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info, color: accentGold),
            const SizedBox(width: 12),
            Text('About MY CAFE ☕', style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.coffee_rounded, size: 48, color: accentGold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'BrewMaster Pro v2.5.0',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Crafted with meticulous attention to detail for a premium management experience. Designed for those who view hospitality as an art form.',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  height: 1.6,
                  color: subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('CLOSE', style: GoogleFonts.hankenGrotesk(color: accentGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showLogoutConfirmDialog(BuildContext context, bool isDark, Color textColor, Color cardColor) {
    final theme = Theme.of(context);
    final subtitleColor = theme.colorScheme.onSurfaceVariant;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Text('Confirm Logout', style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your session?',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            height: 1.6,
            color: subtitleColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text('CANCEL', style: GoogleFonts.hankenGrotesk(color: subtitleColor, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text('LOGOUT', style: GoogleFonts.hankenGrotesk(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTile({
    required IconData icon,
    required Color iconBg,
    Color iconColor = const Color(0xFFD4AF37),
    required String title,
    Color titleColor = const Color(0xFF1A1A1A),
    required String subtitle,
    Color? subtitleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: titleColor,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            color: subtitleColor ?? const Color(0xFFA0A0A0),
          ),
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: (subtitleColor ?? Colors.grey).withOpacity(0.4), size: 22),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 88,
      endIndent: 24,
      color: theme.colorScheme.outline.withOpacity(0.05),
    );
  }
}
