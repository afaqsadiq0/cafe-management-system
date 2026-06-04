import 'package:supabase/supabase.dart';

void main() async {
  final url = 'https://cbsysuoschafitpwpjau.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNic3lzdW9zY2hhZml0cHdwamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTc1MDEsImV4cCI6MjA5MzczMzUwMX0.VOVbK9X_1jkigNafjrGx-x29UY-fQ6UzCiJMvB8BUOw';

  final client = SupabaseClient(url, anonKey);

  try {
    print("Fetching active orders from Supabase...");
    final List<dynamic> response = await client.from('orders').select().limit(5);
    final orders = List<Map<String, dynamic>>.from(response);
    print("Found ${orders.length} orders.");
    for (var o in orders) {
      print("Order ID: ${o['id']}, Status: ${o['status']}");
    }

    if (orders.isNotEmpty) {
      final orderId = orders.first['id'];
      print("Attempting to update status of Order $orderId to 'completed'...");
      final updateRes = await client
          .from('orders')
          .update({'status': 'completed'})
          .eq('id', orderId)
          .select();
      
      print("Response from update: $updateRes");
      if (updateRes.isEmpty) {
        print("WARNING: Update returned empty list! This indicates RLS blocked the update or the ID does not exist.");
      } else {
        print("SUCCESS: Status updated successfully!");
      }
    }
  } catch (e) {
    print("ERROR: $e");
  }
}
