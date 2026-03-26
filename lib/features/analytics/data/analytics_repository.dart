import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../core/database/app_database.dart';

class AnalyticsRepository {
  Database get _db => AppDatabase.instance.db;

  Future<double> getTodayCreditSales() async {
    final now = DateTime.now();
    final startOfDay = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}%";
    
    final result = await _db.rawQuery('''
      SELECT SUM(credit_amount) as total
      FROM transactions
      WHERE created_at LIKE ?
    ''', [startOfDay]);
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalRevenue(DateTime? start, DateTime? end) async {
    // Net Revenue = Final Amount - Returns - Tax (if we want pre-tax revenue)
    // However, if we want to be consistent with item-level reports, we use:
    // SUM(LineSubtotal - ProportionateTax - ProportionateBillDiscount)
    
    String query = '''
      SELECT SUM(
        ( (CAST(ti.quantity AS REAL) - ti.returned_quantity) / ti.quantity ) * 
        ( ti.subtotal - (CASE WHEN t.is_tax_inclusive = 1 THEN ti.tax_amount ELSE 0 END) - (t.discount * ti.subtotal / NULLIF(t.total_amount, 0)) )
      ) as total 
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

  Future<double> getTotalReturns(DateTime? start, DateTime? end) async {
    String query = 'SELECT SUM(refund_amount) as total FROM return_events';
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
      SELECT SUM(ti.cost_at_time * (ti.quantity - ti.returned_quantity)) as total 
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

  Future<double> getTotalSupplierDues() async {
    final result = await _db.rawQuery('SELECT SUM(current_due) as total FROM suppliers');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getTopSuppliers({int limit = 5}) async {
    final result = await _db.rawQuery('''
      SELECT name, total_purchased, current_due
      FROM suppliers
      ORDER BY total_purchased DESC
      LIMIT ?
    ''', [limit]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getTodaySalesByCategory() async {
    final now = DateTime.now();
    final startOfDay = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}%";

    final result = await _db.rawQuery('''
      SELECT c.name as label, SUM((ti.subtotal / ti.quantity) * (ti.quantity - ti.returned_quantity)) as value
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
      JOIN product_variants pv ON ti.product_variant_id = pv.id
      JOIN products p ON pv.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      WHERE t.created_at LIKE ?
      GROUP BY c.id
      ORDER BY value DESC
    ''', [startOfDay]);

    return result;
  }

  Future<List<Map<String, dynamic>>> getSalesByCategory(DateTime? start, DateTime? end) async {
    String query = '''
      SELECT c.name as label, 
      SUM(
        ( (CAST(ti.quantity AS REAL) - ti.returned_quantity) / ti.quantity ) * 
        ( ti.subtotal - (CASE WHEN t.is_tax_inclusive = 1 THEN ti.tax_amount ELSE 0 END) - (t.discount * ti.subtotal / NULLIF(t.total_amount, 0)) )
      ) as value
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
        ti.unit_name,
        SUM(ti.quantity - ti.returned_quantity) as total_qty, 
        SUM(
          ( (CAST(ti.quantity AS REAL) - ti.returned_quantity) / ti.quantity ) * 
          ( ti.subtotal - (CASE WHEN t.is_tax_inclusive = 1 THEN ti.tax_amount ELSE 0 END) - (t.discount * ti.subtotal / NULLIF(t.total_amount, 0)) )
        ) as total_revenue,
        SUM(
          ( (CAST(ti.quantity AS REAL) - ti.returned_quantity) / ti.quantity ) * 
          ( ti.subtotal - (CASE WHEN t.is_tax_inclusive = 1 THEN ti.tax_amount ELSE 0 END) - (t.discount * ti.subtotal / NULLIF(t.total_amount, 0)) - (ti.quantity * ti.cost_at_time) )
        ) as total_profit
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

    query += ' GROUP BY p.id, ti.unit_name ORDER BY total_revenue DESC LIMIT ?';
    args.add(limit.toString());
    
    return await _db.rawQuery(query, args);
  }

  Future<List<Map<String, dynamic>>> getLeastPerformingProducts({int limit = 5}) async {
    // Products with low or zero sales
    final result = await _db.rawQuery('''
      SELECT p.name, ti.unit_name, COALESCE(SUM(ti.quantity), 0) as total_qty
      FROM products p
      LEFT JOIN product_variants pv ON p.id = pv.product_id
      LEFT JOIN transaction_items ti ON pv.id = ti.product_variant_id
      GROUP BY p.id, ti.unit_name
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
      SELECT p.name, sl.available_pieces, sl.low_stock_threshold, pu.unit_name
      FROM stock_levels sl
      JOIN product_variants pv ON sl.product_variant_id = pv.id
      JOIN products p ON pv.product_id = p.id
      LEFT JOIN product_units pu ON pv.id = pu.id
      WHERE sl.available_pieces <= sl.low_stock_threshold
      AND p.is_active = 1
    ''');
  }

  Future<Map<String, double>> getRevenueOverTime(DateTime start, DateTime end) async {
    final result = await _db.rawQuery('''
      SELECT DATE(t.created_at) as date, 
      SUM(
        ( (CAST(ti.quantity AS REAL) - ti.returned_quantity) / ti.quantity ) * 
        ( ti.subtotal - (CASE WHEN t.is_tax_inclusive = 1 THEN ti.tax_amount ELSE 0 END) - (t.discount * ti.subtotal / NULLIF(t.total_amount, 0)) )
      ) as total
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
      WHERE t.created_at BETWEEN ? AND ?
      GROUP BY DATE(t.created_at)
      ORDER BY date ASC
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final Map<String, double> trend = {};
    for (var row in result) {
      trend[row['date'] as String] = (row['total'] as num?)?.toDouble() ?? 0.0;
    }
    return trend;
  }

  Future<Map<String, double>> getTodaySupplyStats() async {
    final now = DateTime.now();
    final startOfDay = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}%";

    final purchaseResult = await _db.rawQuery('''
      SELECT SUM(amount) as total
      FROM supplier_ledgers
      WHERE type = 'PURCHASE' AND created_at LIKE ?
    ''', [startOfDay]);

    final paymentResult = await _db.rawQuery('''
      SELECT SUM(amount) as total
      FROM supplier_ledgers
      WHERE type = 'PAYMENT' AND created_at LIKE ?
    ''', [startOfDay]);

    final totalReceived = (purchaseResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final totalPaid = (paymentResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final dues = totalReceived - totalPaid;

    return {
      'totalReceived': totalReceived,
      'totalPaid': totalPaid,
      'dues': dues,
    };
  }
}
