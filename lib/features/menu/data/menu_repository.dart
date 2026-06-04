import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/local_database.dart';

class MenuRepository {
  final SupabaseClient _supabase;
  final AppDatabase _localDb;

  MenuRepository(this._supabase, this._localDb);

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final data = await _supabase.from('categories').select().order('name');
      // Cache locally
      final localCats = data.map((e) => LocalCategory(
        id: e['id'],
        name: e['name'],
        iconName: e['icon_name'],
      )).toList();
      await _localDb.cacheCategories(localCats);
      return data;
    } catch (e) {
      // Fallback to local
      final localData = await _localDb.select(_localDb.localCategories).get();
      return localData.map((e) => {
        'id': e.id,
        'name': e.name,
        'icon_name': e.iconName,
      }).toList();
    }
  }

  Future<List<Map<String, dynamic>>> getMenuItems() async {
    try {
      final data = await _supabase.from('menu_items').select().order('name');
      // Cache locally
      final localItems = data.map((e) => LocalMenuItem(
        id: e['id'],
        name: e['name'],
        description: e['description'],
        price: (e['price'] as num).toDouble(),
        categoryId: e['category_id'],
        imageUrl: e['image_url'],
        isAvailable: e['is_available'] ?? true,
      )).toList();
      await _localDb.cacheMenuItems(localItems);
      return data;
    } catch (e) {
      // Fallback to local
      final localData = await _localDb.select(_localDb.localMenuItems).get();
      return localData.map((e) => {
        'id': e.id,
        'name': e.name,
        'description': e.description,
        'price': e.price,
        'category_id': e.categoryId,
        'image_url': e.imageUrl,
        'is_available': e.isAvailable,
      }).toList();
    }
  }
}
