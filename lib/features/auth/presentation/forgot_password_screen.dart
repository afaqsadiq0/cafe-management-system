import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.mark_email_read_outlined, size: 80, color: AppTheme.accentColor),
            const SizedBox(height: 32),
            Text(
              'Reset Password', 
              style: GoogleFonts.ebGaramond(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)
            ),
            const SizedBox(height: 16),
            Text(
              'Enter your email address and we will send you a link to reset your password.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(color: AppTheme.onSurfaceVariant.withOpacity(0.6), fontSize: 16),
            ),
            const SizedBox(height: 48),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset link sent! Please check your email.')),
                );
                context.pop();
              },
              child: const Text('SEND RESET LINK'),
            ),
          ],
        ),
      ),
    );
  }
}

