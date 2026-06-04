import 'package:supabase/supabase.dart';

void main() async {
  final url = 'https://cbsysuoschafitpwpjau.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNic3lzdW9zY2hhZml0cHdwamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTc1MDEsImV4cCI6MjA5MzczMzUwMX0.VOVbK9X_1jkigNafjrGx-x29UY-fQ6UzCiJMvB8BUOw';

  final client = SupabaseClient(url, anonKey);

  try {
    print("Fetching profiles...");
    final response = await client.from('profiles').select();
    print("PROFILES: $response");
  } catch (e) {
    print("ERROR: $e");
  }
}
