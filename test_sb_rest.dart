import 'dart:io';
import 'dart:convert';
import 'dart:math';

const String url = 'https://cbsysuoschafitpwpjau.supabase.co';
const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNic3lzdW9zY2hhZml0cHdwamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTc1MDEsImV4cCI6MjA5MzczMzUwMX0.VOVbK9X_1jkigNafjrGx-x29UY-fQ6UzCiJMvB8BUOw';

// Helper to generate a random UUID v4
String generateUuid() {
  final rand = Random();
  final hex = List.generate(32, (i) => rand.nextInt(16).toRadixString(16)).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4${hex.substring(13, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

Future<void> main() async {
  final client = HttpClient();
  final rand = Random().nextInt(1000000);
  final email = 'admin_test_$rand@cafe.com';
  final password = 'password123';

  try {
    // 1. Sign Up
    print("1. Signing up user $email...");
    final signUpUri = Uri.parse('$url/auth/v1/signup');
    final signUpReq = await client.postUrl(signUpUri);
    signUpReq.headers.set('apikey', anonKey);
    signUpReq.headers.set('Content-Type', 'application/json');
    signUpReq.write(jsonEncode({'email': email, 'password': password}));
    final signUpRes = await signUpReq.close();
    final signUpBody = await signUpRes.transform(utf8.decoder).join();
    print("Signup status: ${signUpRes.statusCode}");

    final signUpJson = jsonDecode(signUpBody) as Map<String, dynamic>;
    final userId = signUpJson['id'] ?? signUpJson['user']?['id'];
    final accessToken = signUpJson['access_token'];

    if (userId == null) {
      print("No user ID found in signup response. Body: $signUpBody");
      return;
    }
    print("User ID: $userId");

    // 2. Update Profile Role to admin
    print("\n2. Updating profile role to 'admin'...");
    final profileUri = Uri.parse('$url/rest/v1/profiles?id=eq.$userId');
    final profileReq = await client.patchUrl(profileUri);
    profileReq.headers.set('apikey', anonKey);
    profileReq.headers.set('Authorization', 'Bearer $accessToken');
    profileReq.headers.set('Content-Type', 'application/json');
    profileReq.headers.set('Prefer', 'return=representation');
    profileReq.write(jsonEncode({
      'role': 'admin',
      'full_name': 'Admin User $rand',
    }));
    final profileRes = await profileReq.close();
    final profileBody = await profileRes.transform(utf8.decoder).join();
    print("Profile update status: ${profileRes.statusCode}");
    print("Profile body: $profileBody");

    // 3. Create Order
    final orderId = generateUuid();
    print("\n3. Placing an order with ID $orderId...");
    final orderUri = Uri.parse('$url/rest/v1/orders');
    final orderReq = await client.postUrl(orderUri);
    orderReq.headers.set('apikey', anonKey);
    orderReq.headers.set('Authorization', 'Bearer $accessToken');
    orderReq.headers.set('Content-Type', 'application/json');
    orderReq.headers.set('Prefer', 'return=representation');
    orderReq.write(jsonEncode({
      'id': orderId,
      'staff_id': userId,
      'subtotal': 100.0,
      'tax_amount': 5.0,
      'total_amount': 105.0,
      'payment_method': 'Cash',
      'status': 'pending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }));
    final orderRes = await orderReq.close();
    final orderBody = await orderRes.transform(utf8.decoder).join();
    print("Order insert status: ${orderRes.statusCode}");
    print("Order body: $orderBody");

    // 4. Update Order Status
    print("\n4. Attempting to update order status to 'completed'...");
    final updateUri = Uri.parse('$url/rest/v1/orders?id=eq.$orderId');
    final updateReq = await client.patchUrl(updateUri);
    updateReq.headers.set('apikey', anonKey);
    updateReq.headers.set('Authorization', 'Bearer $accessToken');
    updateReq.headers.set('Content-Type', 'application/json');
    updateReq.headers.set('Prefer', 'return=representation');
    updateReq.write(jsonEncode({
      'status': 'completed',
    }));
    final updateRes = await updateReq.close();
    final updateBody = await updateRes.transform(utf8.decoder).join();
    print("Update status: ${updateRes.statusCode}");
    print("Update body: $updateBody");

  } catch (e) {
    print("ERROR: $e");
  } finally {
    client.close();
  }
}
