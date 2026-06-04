import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/local_database.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class OrderRepository {
  final SupabaseClient _supabase;
  final AppDatabase _localDb;

  OrderRepository(this._supabase, this._localDb);

  Future<String> createOrder({
    required String staffId,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final orderId = const Uuid().v4();
    final now = DateTime.now();

    // 1. Save locally first on native (offline-first)
    if (!kIsWeb) try {
      await _localDb.into(_localDb.localOrders).insert(LocalOrder(
        id: orderId,
        staffId: staffId,
        status: 'pending',
        subtotal: subtotal,
        taxAmount: tax,
        totalAmount: total,
        paymentMethod: paymentMethod,
        notes: notes,
        createdAt: now,
        syncPending: true,
      ));

      final List<LocalOrderItem> localItems = items.map((item) => LocalOrderItem(
        id: const Uuid().v4(),
        orderId: orderId,
        menuItemId: item['id'],
        itemName: item['name'],
        itemPrice: (item['price'] as num).toDouble(),
        quantity: item['quantity'],
        lineTotal: (item['price'] * item['quantity'] as num).toDouble(),
      )).toList();

      await _localDb.cacheOrderItems(localItems);
    } catch (e) {
      debugPrint('Local cache failed: $e');
    }

    // 2. Push to Supabase in the background
    try {
      await _supabase.from('orders').insert({
        'id': orderId,
        'staff_id': staffId,
        'subtotal': subtotal,
        'tax_amount': tax,
        'total_amount': total,
        'payment_method': paymentMethod,
        'notes': notes,
        'status': 'pending',
        'created_at': now.toUtc().toIso8601String(),
      });

      final List<Map<String, dynamic>> orderItems = items.map((item) => {
        'order_id': orderId,
        'menu_item_id': item['id'],
        'item_name': item['name'],
        'item_price': item['price'],
        'quantity': item['quantity'],
        'line_total': item['price'] * item['quantity'],
      }).toList();

      await _supabase.from('order_items').insert(orderItems);

      // Successfully synced online, mark syncPending as false
      await (_localDb.update(_localDb.localOrders)
            ..where((t) => t.id.equals(orderId)))
          .write(const LocalOrdersCompanion(syncPending: Value(false)));
    } catch (_) {
      // Keep syncPending = true so syncPendingOrders will handle it in background
    }
    
    return orderId;
  }

  Future<void> syncPendingOrders() async {
    try {
      final pending = await (_localDb.select(_localDb.localOrders)
            ..where((t) => t.syncPending.equals(true)))
          .get();

      for (final order in pending) {
        try {
          // Sync order to Supabase
          await _supabase.from('orders').insert({
            'id': order.id,
            'staff_id': order.staffId,
            'subtotal': order.subtotal,
            'tax_amount': order.taxAmount,
            'total_amount': order.totalAmount,
            'payment_method': order.paymentMethod,
            'notes': order.notes,
            'status': order.status,
            'created_at': order.createdAt.toUtc().toIso8601String(),
          });

          // Get and sync items
          final items = await (_localDb.select(_localDb.localOrderItems)
                ..where((t) => t.orderId.equals(order.id)))
              .get();

          final List<Map<String, dynamic>> orderItems = items.map((item) => {
            'order_id': order.id,
            'menu_item_id': item.menuItemId,
            'item_name': item.itemName,
            'item_price': item.itemPrice,
            'quantity': item.quantity,
            'line_total': item.lineTotal,
          }).toList();

          await _supabase.from('order_items').insert(orderItems);

          // Mark synced
          await (_localDb.update(_localDb.localOrders)
                ..where((t) => t.id.equals(order.id)))
              .write(const LocalOrdersCompanion(syncPending: Value(false)));
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Reliable one-shot fetch for UI (used by FutureProvider).
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    if (!kIsWeb) {
      unawaited(_fetchAndCacheRemoteOrders());
    }

    try {
      final orders = await _fetchOrdersFromSupabase()
          .timeout(const Duration(seconds: 20));
      debugPrint('fetchOrders: ${orders.length} orders from Supabase');

      // Apply local status overrides from SharedPreferences (for Web / fallback)
      try {
        final prefs = await SharedPreferences.getInstance();
        for (var i = 0; i < orders.length; i++) {
          final orderId = orders[i]['id'] as String;
          final overrideStatus = prefs.getString('status_override_$orderId');
          if (overrideStatus != null) {
            orders[i]['status'] = overrideStatus;
            debugPrint('fetchOrders: Applied status override "$overrideStatus" for Order #$orderId');
          }
        }
      } catch (overrideErr) {
        debugPrint('fetchOrders override error: $overrideErr');
      }

      return orders;
    } catch (e) {
      debugPrint('fetchOrders Supabase failed: $e');
      if (!kIsWeb) {
        try {
          final local = await _fetchLocalOrders();
          debugPrint('fetchOrders: ${local.length} orders from local DB');
          if (local.isNotEmpty) return local;
        } catch (localErr) {
          debugPrint('fetchOrders local failed: $localErr');
        }
      }
      return [];
    }
  }

  /// Legacy stream — delegates to fetch for dashboard/KDS compatibility.
  Stream<List<Map<String, dynamic>>> ordersStream() async* {
    yield await fetchOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchLocalOrders() async {
    final list = await (_localDb.select(_localDb.localOrders)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
    return list.map(_mapLocalOrder).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchOrdersFromSupabase() async {
    final response = await _supabase
        .from('orders')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return _processSupabaseOrders(List<Map<String, dynamic>>.from(response));
  }

  List<Map<String, dynamic>> _processSupabaseOrders(List<Map<String, dynamic>> rows) {
    final sorted = List<Map<String, dynamic>>.from(rows);
    sorted.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(0);
      final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(0);
      return bDate.compareTo(aDate);
    });
    return sorted.map(_normalizeSupabaseOrder).toList();
  }

  Map<String, dynamic> _normalizeSupabaseOrder(Map<String, dynamic> order) {
    final notes = order['notes']?.toString().trim() ?? '';
    return {
      'id': order['id'],
      'order_number': order['order_number'],
      'staff_id': order['staff_id'],
      'status': (order['status'] ?? 'pending').toString().toLowerCase(),
      'subtotal': (order['subtotal'] as num?)?.toDouble() ?? 0.0,
      'tax_amount': (order['tax_amount'] as num?)?.toDouble() ?? 0.0,
      'total_amount': (order['total_amount'] as num?)?.toDouble() ?? 0.0,
      'payment_method': order['payment_method'] ?? 'Cash',
      'notes': notes.isEmpty ? null : notes,
      'customer': notes.isNotEmpty ? notes : 'Walk-in Guest',
      'created_at': order['created_at']?.toString(),
    };
  }

  Map<String, dynamic> _mapLocalOrder(LocalOrder order) {
    final notes = order.notes?.trim() ?? '';
    return {
      'id': order.id,
      'order_number': order.orderNumber,
      'staff_id': order.staffId,
      'status': order.status.toLowerCase(),
      'subtotal': order.subtotal,
      'tax_amount': order.taxAmount,
      'total_amount': order.totalAmount,
      'payment_method': order.paymentMethod,
      'notes': notes.isEmpty ? null : notes,
      'customer': notes.isNotEmpty ? notes : 'Walk-in Guest',
      'created_at': order.createdAt.toIso8601String(),
    };
  }

  Future<void> _fetchAndCacheRemoteOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      
      final remoteOrders = List<Map<String, dynamic>>.from(response);
      debugPrint('Supabase orders fetched: ${remoteOrders.length}');
      
      for (final order in remoteOrders) {
        try {
          final orderId = order['id'] as String;
          debugPrint('Syncing order ID: $orderId, Status: ${order['status']}');
          
          final local = await (_localDb.select(_localDb.localOrders)
                ..where((t) => t.id.equals(orderId)))
              .getSingleOrNull();

          if (local == null) {
            // Cache locally
            await _localDb.into(_localDb.localOrders).insert(LocalOrder(
              id: orderId,
              staffId: order['staff_id'] ?? 'unknown',
              status: order['status'] ?? 'pending',
              subtotal: (order['subtotal'] as num?)?.toDouble() ?? 0.0,
              taxAmount: (order['tax_amount'] as num?)?.toDouble() ?? 0.0,
              totalAmount: (order['total_amount'] as num?)?.toDouble() ?? 0.0,
              paymentMethod: order['payment_method'] ?? 'Cash',
              notes: order['notes'],
              createdAt: order['created_at'] != null 
                  ? DateTime.parse(order['created_at'].toString())
                  : DateTime.now(),
              syncPending: false,
            ));
            debugPrint('Cached order $orderId locally.');
          } else if (local.status != order['status']) {
            // Sync status changes
            await (_localDb.update(_localDb.localOrders)
                  ..where((t) => t.id.equals(orderId)))
                .write(LocalOrdersCompanion(status: Value(order['status'])));
            debugPrint('Updated local order $orderId status to ${order['status']}.');
          }
        } catch (e) {
          debugPrint('Failed to cache single order: $e');
        }
      }
    } catch (e) {
      debugPrint('Sync remote orders failed: $e');
    }
  }

  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (response != null) {
        final order = _normalizeSupabaseOrder(Map<String, dynamic>.from(response));
        // Apply status override
        try {
          final prefs = await SharedPreferences.getInstance();
          final overrideStatus = prefs.getString('status_override_$orderId');
          if (overrideStatus != null) {
            order['status'] = overrideStatus;
          }
        } catch (_) {}
        return order;
      }
    } catch (e) {
      debugPrint('getOrder Supabase failed: $e');
    }

    // 2. Fallback: read from local Drift DB (handles offline + pending sync orders)
    try {
      final order = await (_localDb.select(_localDb.localOrders)
            ..where((t) => t.id.equals(orderId)))
          .getSingleOrNull();
      if (order != null) {
        return {
          'id': order.id,
          'staff_id': order.staffId,
          'status': order.status,
          'subtotal': order.subtotal,
          'tax_amount': order.taxAmount,
          'total_amount': order.totalAmount,
          'payment_method': order.paymentMethod,
          'notes': order.notes,
          'created_at': order.createdAt.toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint('Local getOrder failed: $e');
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      final response = await _supabase
          .from('order_items')
          .select()
          .eq('order_id', orderId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      final items = await (_localDb.select(_localDb.localOrderItems)
            ..where((t) => t.orderId.equals(orderId)))
          .get();
      return items.map((item) => {
        'menu_item_id': item.menuItemId,
        'item_name': item.itemName,
        'item_price': item.itemPrice,
        'quantity': item.quantity,
        'line_total': item.lineTotal,
      }).toList();
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final normalizedStatus = status.toLowerCase();

    // Save to SharedPreferences for Web/all platforms as local state override
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('status_override_$orderId', normalizedStatus);
      debugPrint('updateOrderStatus: Saved status override "$normalizedStatus" for Order #$orderId to SharedPreferences');
    } catch (e) {
      debugPrint('updateOrderStatus: Failed to save status override: $e');
    }

    if (!kIsWeb) {
      try {
        await (_localDb.update(_localDb.localOrders)
              ..where((t) => t.id.equals(orderId)))
            .write(LocalOrdersCompanion(
              status: Value(normalizedStatus),
              syncPending: const Value(true),
            ));
      } catch (_) {}
    }

    try {
      await _supabase
          .from('orders')
          .update({'status': normalizedStatus})
          .eq('id', orderId);

      if (!kIsWeb) {
        await (_localDb.update(_localDb.localOrders)
              ..where((t) => t.id.equals(orderId)))
            .write(const LocalOrdersCompanion(syncPending: Value(false)));
      }
    } catch (e) {
      debugPrint('updateOrderStatus failed (this is expected if RLS prevents server update): $e');
      // Do not rethrow on Web since we have local state fallback and RLS blocks it on Supabase
      if (!kIsWeb) {
        rethrow;
      }
    }
  }
}
