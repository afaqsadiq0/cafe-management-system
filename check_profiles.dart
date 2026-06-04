import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'lib/core/supabase/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  try {
    final res = await SupabaseConfig.client.from('profiles').select().limit(5);
    print("PROFILES: $res");
  } catch(e) {
    print("ERROR: $e");
  }
}
