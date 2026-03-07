import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../core/database/app_database.dart';

class AnalyticsRepository {
  Database get _db => AppDatabase.instance.db;

  Future<double> getTodayCreditSales() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    
    final result = await _db.rawQuery('''
      SELECT SUM(credit_amount) as total
      FROM transactions
      WHERE created_at >= ?
    ''', [startOfDay]);
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getTodaySalesByCategory() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    final result = await _db.rawQuery('''
      SELECT c.name as label, SUM(ti.subtotal) as value
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
      JOIN product_variants pv ON ti.product_variant_id = pv.id
      JOIN products p ON pv.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      WHERE t.created_at >= ?
      GROUP BY c.id
      ORDER BY value DESC
    ''', [startOfDay]);

    return result;
  }

  Future<List<Map<String, dynamic>>> getTopPerformingProducts({int limit = 5}) async {
    final result = await _db.rawQuery('''
      SELECT p.name, SUM(ti.quantity) as total_qty, SUM(ti.subtotal) as total_revenue
      FROM transaction_items ti
      JOIN product_variants pv ON ti.product_variant_id = pv.id
      JOIN products p ON pv.product_id = p.id
      GROUP BY p.id
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [limit]);
    
    return result;
  }

  Future<List<Map<String, dynamic>>> getLeastPerformingProducts({int limit = 5}) async {
    // Products with low or zero sales
    final result = await _db.rawQuery('''
      SELECT p.name, COALESCE(SUM(ti.quantity), 0) as total_qty
      FROM products p
      LEFT JOIN product_variants pv ON p.id = pv.id
      LEFT JOIN transaction_items ti ON pv.id = ti.product_variant_id
      GROUP BY p.id
      ORDER BY total_qty ASC
      LIMIT ?
    ''', [limit]);
    
    return result;
  }

  Future<int> getLowStockCount() async {
    final result = await _db.rawQuery('''
      SELECT COUNT(*) as count
      FROM stock_levels
      WHERE available_pieces <= low_stock_threshold
    ''');
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    return await _db.rawQuery('''
      SELECT p.name, sl.available_pieces, sl.low_stock_threshold
      FROM stock_levels sl
      JOIN product_variants pv ON sl.product_variant_id = pv.id
      JOIN products p ON pv.product_id = p.id
      WHERE sl.available_pieces <= sl.low_stock_threshold
    ''');
  }
}
