import 'dart:io';
import 'dart:convert';
import 'dart:math';

const String url = 'https://cbsysuoschafitpwpjau.supabase.co';
const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNic3lzdW9zY2hhZml0cHdwamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTc1MDEsImV4cCI6MjA5MzczMzUwMX0.VOVbK9X_1jkigNafjrGx-x29UY-fQ6UzCiJMvB8BUOw';

String generateUuid() {
  final rand = Random();
  final hex = List.generate(32, (i) => rand.nextInt(16).toRadixString(16)).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4${hex.substring(13, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

Future<void> main() async {
  final client = HttpClient();
  final rand = Random().nextInt(1000000);
  final email = 'field_test_$rand@cafe.com';
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
    final signUpJson = jsonDecode(signUpBody) as Map<String, dynamic>;
    final userId = signUpJson['id'] ?? signUpJson['user']?['id'];
    final accessToken = signUpJson['access_token'];

    // 2. Create Order
    final orderId = generateUuid();
    print("\n2. Placing an order with ID $orderId...");
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
      'notes': 'Original Notes',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }));
    final orderRes = await orderReq.close();
    final orderBody = await orderRes.transform(utf8.decoder).join();
    print("Order insert status: ${orderRes.statusCode}");

    // 3. Try to update notes (keeping status pending)
    print("\n3. Attempting to update notes to 'Updated Notes' (status stays pending)...");
    final updateNotesUri = Uri.parse('$url/rest/v1/orders?id=eq.$orderId');
    final updateNotesReq = await client.patchUrl(updateNotesUri);
    updateNotesReq.headers.set('apikey', anonKey);
    updateNotesReq.headers.set('Authorization', 'Bearer $accessToken');
    updateNotesReq.headers.set('Content-Type', 'application/json');
    updateNotesReq.headers.set('Prefer', 'return=representation');
    updateNotesReq.write(jsonEncode({
      'notes': 'Updated Notes',
    }));
    final updateNotesRes = await updateNotesReq.close();
    final updateNotesBody = await updateNotesRes.transform(utf8.decoder).join();
    print("Update Notes status: ${updateNotesRes.statusCode}");
    print("Update Notes body: $updateNotesBody");

    // 4. Try to update status to 'completed'
    print("\n4. Attempting to update status to 'completed'...");
    final updateStatusUri = Uri.parse('$url/rest/v1/orders?id=eq.$orderId');
    final updateStatusReq = await client.patchUrl(updateStatusUri);
    updateStatusReq.headers.set('apikey', anonKey);
    updateStatusReq.headers.set('Authorization', 'Bearer $accessToken');
    updateStatusReq.headers.set('Content-Type', 'application/json');
    updateStatusReq.headers.set('Prefer', 'return=representation');
    updateStatusReq.write(jsonEncode({
      'status': 'completed',
    }));
    final updateStatusRes = await updateStatusReq.close();
    final updateStatusBody = await updateStatusRes.transform(utf8.decoder).join();
    print("Update Status status: ${updateStatusRes.statusCode}");
    print("Update Status body: $updateStatusBody");

  } catch (e) {
    print("ERROR: $e");
  } finally {
    client.close();
  }
}
