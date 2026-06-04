import 'package:supabase/supabase.dart';
import 'dart:math';

void main() async {
  final url = 'https://cbsysuoschafitpwpjau.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNic3lzdW9zY2hhZml0cHdwamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTc1MDEsImV4cCI6MjA5MzczMzUwMX0.VOVbK9X_1jkigNafjrGx-x29UY-fQ6UzCiJMvB8BUOw';
  
  final client = SupabaseClient(url, anonKey);
  
  final rand = Random().nextInt(1000000);
  final email = 'test$rand@example.com';
  
  try {
    print("--- Diagnostic Start ---");
    print("Testing signup with: $email");
    
    final response = await client.auth.signUp(email: email, password: 'password123');
    final userId = response.user?.id;
    print("Step 1: Auth Signup -> SUCCESS (ID: $userId)");
    
    if (userId != null) {
      print("Step 2: Testing insertion into 'profiles' table...");
      try {
        await client.from('profiles').insert({
          'id': userId,
          'full_name': 'Diagnostic User',
          'role': 'staff',
        });
        print("Step 2: Profile Insertion -> SUCCESS");
      } catch (e) {
        print("Step 2: Profile Insertion -> FAILED: $e");
        print("\nPossible Reason: Row Level Security (RLS) is blocking the insert, or table 'profiles' is missing.");
      }
    }
    print("--- Diagnostic End ---");
  } catch (e) {
    print("Step 1: Auth Signup -> FAILED: $e");
  }
}
