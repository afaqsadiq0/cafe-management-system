import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/supabase_config.dart';
import '../database/local_database.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/menu/data/menu_repository.dart';
import '../../features/orders/data/order_repository.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';

final supabaseClientProvider = Provider((ref) => SupabaseConfig.client);

final localDbProvider = Provider((ref) => AppDatabase());

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final menuRepositoryProvider = Provider((ref) {
  return MenuRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(localDbProvider),
  );
});

final orderRepositoryProvider = Provider((ref) {
  return OrderRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(localDbProvider),
  );
});

final syncServiceProvider = Provider((ref) {
  return SyncService(ref.watch(orderRepositoryProvider));
});

final orderNotificationServiceProvider = Provider((ref) {
  return OrderNotificationService(ref.watch(supabaseClientProvider));
});

