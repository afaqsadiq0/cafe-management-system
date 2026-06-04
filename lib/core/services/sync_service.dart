import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/orders/data/order_repository.dart';
import 'package:flutter/material.dart';

class SyncService {
  final OrderRepository _orderRepository;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  SyncService(this._orderRepository);

  void start(BuildContext context) {
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || 
          results.contains(ConnectivityResult.wifi) || 
          results.contains(ConnectivityResult.ethernet)) {
        
        _performSync(context);
      }
    });
  }

  Future<void> _performSync(BuildContext context) async {
    try {
      await _orderRepository.syncPendingOrders();
      // Optionally show a snackbar if we are in a widget context or use a global key
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  void stop() {
    _subscription?.cancel();
  }
}
