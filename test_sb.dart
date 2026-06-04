import 'package:supabase/supabase.dart';
import 'dart:math';

void main() async {
  final supabaseUrl = 'https://cbsysuoschafitpwpjau.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNic3lzdW9zY2hhZml0cHdwamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTc1MDEsImV4cCI6MjA5MzczMzUwMX0.VOVbK9X_1jkigNafjrGx-x29UY-fQ6UzCiJMvB8BUOw';
  
  final client = SupabaseClient(supabaseUrl, supabaseKey);
  final rand = Random().nextInt(10000);
  final newEmail = 'testuser2_$rand@cafe.com';
  
  try {
    print('Attempting to create user: $newEmail');
    final authRes = await client.auth.signUp(email: newEmail, password: 'password123');
    print('Signup Response: $authRes');
    print('User: ${authRes.user}');
    print('Session: ${authRes.session}');
    
    if (authRes.user != null) {
      print('Inserting into profiles...');
      final insertRes = await client.from('profiles').insert({
        'id': authRes.user!.id,
        'full_name': 'Test User $rand',
        'role': 'staff',
      }).select();
      print('Profile created successfully: $insertRes');
    } else {
      print('USER IS NULL. Email confirmations might be enabled, or fake response.');
    }
  } catch (e, stack) {
    print('CAUGHT ERROR: $e');
    print('STACK: $stack');
  }
}
