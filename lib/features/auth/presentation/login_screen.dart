import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/repository_providers.dart';
import '../../orders/domain/orders_providers.dart';
import '../../../core/animations/spring_scale_button.dart';
import '../../../core/widgets/animated_typewriter_text.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || (!_isLogin && _nameController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await ref.read(authRepositoryProvider).signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await ref.read(authRepositoryProvider).signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          'staff',
        );
      }
      ref.invalidate(ordersListProvider);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building LoginScreen...');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurfaceVariant;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final accentGold = isDark ? AppTheme.darkAccentColor : AppTheme.secondaryColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Texture
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.05 : 0.03,
              child: Image.network(
                'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?q=80&w=2000',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: bgColor),
              ),
            ),
          ),
          
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Brand Header
                  Hero(
                    tag: 'logo',
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: accentGold.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: accentGold.withOpacity(0.2)),
                          ),
                          child: Icon(Icons.coffee_maker_rounded, color: accentGold, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'MY CAFE',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'ARTISANAL CONCIERGE',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: accentGold,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Auth Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tab Switcher
                        Container(
                          height: 64,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.02),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                          ),
                          child: Row(
                            children: [
                              _buildTabButton('LOGIN', _isLogin, () => setState(() => _isLogin = true), theme, accentGold),
                              _buildTabButton('SIGNUP', !_isLogin, () => setState(() => _isLogin = false), theme, accentGold),
                            ],
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                          child: Column(
                            children: [
                              AnimatedTypewriterText(
                                key: ValueKey(_isLogin),
                                text: _isLogin ? 'Welcome Back' : 'Join the Craft',
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                                speed: const Duration(milliseconds: 60),
                                enableSound: true,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isLogin 
                                  ? 'Enter your credentials to manage your boutique cafe.' 
                                  : 'Begin your journey with our master curators.',
                                style: GoogleFonts.hankenGrotesk(
                                  color: subtitleColor,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 40),
                              
                              if (!_isLogin) ...[
                                _buildTextField('Full Name', _nameController, Icons.person_outline_rounded, theme),
                                const SizedBox(height: 20),
                              ],
                              _buildTextField('Email Address', _emailController, Icons.email_outlined, theme),
                              const SizedBox(height: 20),
                              _buildTextField(
                                'Password', 
                                _passwordController, 
                                Icons.lock_outline_rounded, 
                                theme,
                                isPassword: true,
                              ),
                              
                              if (_isLogin)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.hankenGrotesk(
                                        color: accentGold,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              
                              const SizedBox(height: 32),
                              
                              _isLoading
                                ? CircularProgressIndicator(color: accentGold)
                                : SpringScaleButton(
                                    onPressed: _handleAuth,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isDark 
                                            ? [accentGold, accentGold.withOpacity(0.8)]
                                            : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.9)],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isDark ? accentGold : theme.colorScheme.primary).withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          _isLogin ? 'SIGN IN' : 'CREATE ACCOUNT',
                                          style: GoogleFonts.hankenGrotesk(
                                            color: isDark ? Colors.black : Colors.white, 
                                            fontWeight: FontWeight.w900, 
                                            letterSpacing: 2,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: theme.colorScheme.outline.withOpacity(0.1))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'AUTHENTICATED ACCESS',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 9,
                                        color: subtitleColor.withOpacity(0.5),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: theme.colorScheme.outline.withOpacity(0.1))),
                                ],
                              ),
                              const SizedBox(height: 32),
                              
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.security_rounded, size: 18),
                                label: const Text('SECURE GOOGLE ACCESS'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 58),
                                  side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  Text(
                    'PRECISION IN EVERY POUR\nEXCELLENCE IN EVERY DETAIL',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: textColor.withOpacity(0.3),
                      letterSpacing: 3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap, ThemeData theme, Color accentGold) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isSelected ? Colors.transparent : theme.colorScheme.onSurface.withOpacity(0.02),
            border: Border(
              bottom: BorderSide(
                color: isSelected ? accentGold : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 12,
                letterSpacing: 1.5,
                color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, ThemeData theme, {bool isPassword = false}) {
    final subtitleColor = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.hankenGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: subtitleColor,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Enter your ${label.toLowerCase()}',
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          ),
        ),
      ],
    );
  }
}
