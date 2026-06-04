import 'package:supabase/supabase.dart';
import 'dart:math';

void main() async {
  final url = 'https://cbsysuoschafitpwpjau.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNic3lzdW9zY2hhZml0cHdwamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTc1MDEsImV4cCI6MjA5MzczMzUwMX0.VOVbK9X_1jkigNafjrGx-x29UY-fQ6UzCiJMvB8BUOw';

  final client = SupabaseClient(url, anonKey);
  final rand = Random().nextInt(1000000);
  final email = 'test_update_$rand@cafe.com';
  final password = 'password123';

  try {
    print("Step 1: Signing up user $email...");
    final authRes = await client.auth.signUp(email: email, password: password);
    final userId = authRes.user?.id;
    print("User ID: $userId");

    if (userId == null) {
      print("Failed to sign up.");
      return;
    }

    print("Step 2: Inserting profile...");
    final profileRes = await client.from('profiles').insert({
      'id': userId,
      'full_name': 'Test User $rand',
      'role': 'staff',
    }).select();
    print("Profile created: $profileRes");

    // Wait a brief moment
    await Future.delayed(const Duration(seconds: 1));

    print("Step 3: Creating a new order under staff_id $userId...");
    final orderId = 'test-order-$rand';
    final orderRes = await client.from('orders').insert({
      'id': orderId,
      'staff_id': userId,
      'subtotal': 100.0,
      'tax_amount': 5.0,
      'total_amount': 105.0,
      'payment_method': 'Cash',
      'status': 'pending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }).select();
    print("Order created: $orderRes");

    print("Step 4: Attempting to update the order status to 'completed'...");
    final updateRes = await client
        .from('orders')
        .update({'status': 'completed'})
        .eq('id', orderId)
        .select();
    
    print("Update Response: $updateRes");
    if (updateRes.isEmpty) {
      print("WARNING: Update returned empty list! RLS is blocking updates even for the owner/creator.");
    } else {
      print("SUCCESS: Order status updated successfully!");
    }
  } catch (e) {
    print("ERROR: $e");
  }
}
