import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor openConnection() {
  return WebDatabase('my_cafe_db');
}
