import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/app_database.dart';

class StockMovementRepository {
  Database get _db => AppDatabase.instance.db;

  Future<List<Map<String, Object?>>> getRecent({int limit = 50}) {
    return _db.query(
      'stock_movements',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }
}

