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

  Future<double> getTotalRevenue(DateTime? start, DateTime? end) async {
    String query = 'SELECT SUM(final_amount) as total FROM transactions';
    List<String> args = [];
    
    if (start != null || end != null) {
      query += ' WHERE ';
      if (start != null && end != null) {
        query += 'created_at BETWEEN ? AND ?';
        args.addAll([start.toIso8601String(), end.toIso8601String()]);
      } else if (start != null) {
        query += 'created_at >= ?';
        args.add(start.toIso8601String());
      } else {
        query += 'created_at <= ?';
        args.add(end!.toIso8601String());
      }
    }
    
    final result = await _db.rawQuery(query, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalCost(DateTime? start, DateTime? end) async {
    String query = '''
      SELECT SUM(ti.cost_at_time * ti.quantity) as total 
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
    ''';
    List<String> args = [];
    
    if (start != null || end != null) {
      query += ' WHERE ';
      if (start != null && end != null) {
        query += 't.created_at BETWEEN ? AND ?';
        args.addAll([start.toIso8601String(), end.toIso8601String()]);
      } else if (start != null) {
        query += 't.created_at >= ?';
        args.add(start.toIso8601String());
      } else {
        query += 't.created_at <= ?';
        args.add(end!.toIso8601String());
      }
    }
    
    final result = await _db.rawQuery(query, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalCreditToCollect() async {
    final result = await _db.rawQuery('SELECT SUM(current_credit) as total FROM customers');
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

  Future<List<Map<String, dynamic>>> getSalesByCategory(DateTime? start, DateTime? end) async {
    String query = '''
      SELECT c.name as label, SUM(ti.subtotal) as value
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
      JOIN product_variants pv ON ti.product_variant_id = pv.id
      JOIN products p ON pv.product_id = p.id
      JOIN categories c ON p.category_id = c.id
    ''';
    List<String> args = [];
    
    if (start != null || end != null) {
      query += ' WHERE ';
      if (start != null && end != null) {
        query += 't.created_at BETWEEN ? AND ?';
        args.addAll([start.toIso8601String(), end.toIso8601String()]);
      } else if (start != null) {
        query += 't.created_at >= ?';
        args.add(start.toIso8601String());
      } else {
        query += 't.created_at <= ?';
        args.add(end!.toIso8601String());
      }
    }
    
    query += ' GROUP BY c.id ORDER BY value DESC';
    return await _db.rawQuery(query, args);
  }

  Future<List<Map<String, dynamic>>> getTopPerformingProducts({int limit = 10, DateTime? start, DateTime? end}) async {
    String query = '''
      SELECT 
        p.name, 
        SUM(ti.quantity) as total_qty, 
        SUM(ti.subtotal) as total_revenue,
        SUM(ti.subtotal - (ti.cost_at_time * ti.quantity)) as total_profit
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
      JOIN product_variants pv ON ti.product_variant_id = pv.id
      JOIN products p ON pv.product_id = p.id
    ''';
    List<String> args = [];

    if (start != null || end != null) {
      query += ' WHERE ';
      if (start != null && end != null) {
        query += 't.created_at BETWEEN ? AND ?';
        args.addAll([start.toIso8601String(), end.toIso8601String()]);
      } else if (start != null) {
        query += 't.created_at >= ?';
        args.add(start.toIso8601String());
      } else {
        query += 't.created_at <= ?';
        args.add(end!.toIso8601String());
      }
    }

    query += ' GROUP BY p.id ORDER BY total_revenue DESC LIMIT ?';
    args.add(limit.toString());
    
    return await _db.rawQuery(query, args);
  }

  Future<List<Map<String, dynamic>>> getLeastPerformingProducts({int limit = 5}) async {
    // Products with low or zero sales
    final result = await _db.rawQuery('''
      SELECT p.name, COALESCE(SUM(ti.quantity), 0) as total_qty
      FROM products p
      LEFT JOIN product_variants pv ON p.id = pv.product_id
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
      FROM stock_levels sl
      JOIN product_variants pv ON sl.product_variant_id = pv.id
      JOIN products p ON pv.product_id = p.id
      WHERE sl.available_pieces <= sl.low_stock_threshold
      AND p.is_active = 1
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
      AND p.is_active = 1
    ''');
  }

  Future<Map<String, double>> getRevenueOverTime(DateTime start, DateTime end) async {
    final result = await _db.rawQuery('''
      SELECT DATE(created_at) as date, SUM(final_amount) as total
      FROM transactions
      WHERE created_at BETWEEN ? AND ?
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final Map<String, double> trend = {};
    for (var row in result) {
      trend[row['date'] as String] = (row['total'] as num?)?.toDouble() ?? 0.0;
    }
    return trend;
  }
}
