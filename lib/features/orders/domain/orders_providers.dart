import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/domain/auth_providers.dart';

/// Loads all orders — refreshes when invalidated manually or after status update.
final ordersListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authStateProvider);
  final currentUser = ref.read(supabaseClientProvider).auth.currentUser;
  debugPrint('ordersListProvider: Current authenticated user ID is: "${currentUser?.id}"');
  final orders = await ref.read(orderRepositoryProvider).fetchOrders();
  debugPrint('ordersListProvider: loaded ${orders.length} orders');
  for (final o in orders) {
    debugPrint('Order #${o['id'].toString().substring(0, 6)} - Status: "${o['status']}" - Staff ID: "${o['staff_id']}"');
  }
  return orders;
});

