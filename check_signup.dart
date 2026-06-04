import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'lib/core/supabase/supabase_config.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  
  final rand = Random().nextInt(1000000);
  final email = 'test$rand@example.com';
  
  try {
    print("Trying to signup $email");
    final response = await SupabaseConfig.client.auth.signUp(email: email, password: 'password123');
    print("Signup successful! User ID: ${response.user?.id}");
    
    if (response.user != null) {
      print("Trying to insert into profiles...");
      await SupabaseConfig.client.from('profiles').insert({
        'id': response.user!.id,
        'full_name': 'Test User',
        'role': 'staff',
      });
      print("Profile inserted successfully!");
    }
  } catch(e) {
    print("ERROR DURING TEST: $e");
  }
}
