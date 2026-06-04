import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../../core/providers/repository_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  final user = authState?.session?.user ?? ref.watch(supabaseClientProvider).auth.currentUser;
  
  if (user == null) return null;

  try {
    final response = await ref.watch(supabaseClientProvider)
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    
    return response;
  } catch (e) {
    return null;
  }
});
