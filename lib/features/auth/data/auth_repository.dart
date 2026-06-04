import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_config.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password, String fullName, String role) async {
    final response = await _client.auth.signUp(email: email, password: password);
    if (response.user != null) {
      await _client.from('profiles').upsert({
        'id': response.user!.id,
        'full_name': fullName,
        'role': role,
      });
    }
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
}
