import 'package:drift/drift.dart';
import 'unsupported.dart'
    if (dart.library.html) 'web_connection.dart'
    if (dart.library.io) 'native_connection.dart';

part 'local_database.g.dart';

class LocalCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get iconName => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalMenuItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  TextColumn get categoryId => text()();
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalOrders extends Table {
  TextColumn get id => text()();
  IntColumn get orderNumber => integer().nullable()();
  TextColumn get staffId => text()();
  TextColumn get status => text()();
  RealColumn get subtotal => real()();
  RealColumn get taxAmount => real()();
  RealColumn get totalAmount => real()();
  TextColumn get paymentMethod => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get syncPending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalOrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get menuItemId => text()();
  TextColumn get itemName => text()();
  RealColumn get itemPrice => real()();
  IntColumn get quantity => integer()();
  RealColumn get lineTotal => real()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [LocalCategories, LocalMenuItems, LocalOrders, LocalOrderItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;

  // Helpers
  Future<void> cacheCategories(List<LocalCategory> categories) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localCategories, categories);
    });
  }

  Future<void> cacheMenuItems(List<LocalMenuItem> items) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localMenuItems, items);
    });
  }

  Future<void> cacheOrders(List<LocalOrder> orders) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localOrders, orders);
    });
  }

  Future<void> cacheOrderItems(List<LocalOrderItem> items) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localOrderItems, items);
    });
  }
}
