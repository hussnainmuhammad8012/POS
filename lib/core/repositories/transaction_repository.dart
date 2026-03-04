import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import '../database/app_database.dart';
import '../models/entities.dart';

class TransactionRepository {
  Database get _db => AppDatabase.instance.db;

  Future<Transaction> insertTransaction({
    required Transaction transaction,
    required List<TransactionItem> items,
  }) async {
    return _db.transaction((txn) async {
      final txId = await txn.insert('transactions', {
        'invoice_number': transaction.invoiceNumber,
        'customer_id': transaction.customerId,
        'total_amount': transaction.totalAmount,
        'discount': transaction.discount,
        'tax': transaction.tax,
        'final_amount': transaction.finalAmount,
        'payment_method': transaction.paymentMethod,
        'payment_status': transaction.paymentStatus,
        'created_at': transaction.createdAt.toIso8601String(),
      });

      for (final item in items) {
        await txn.insert('transaction_items', {
          'transaction_id': txId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price_at_time': item.priceAtTime,
          'cost_at_time': item.costAtTime,
          'subtotal': item.subtotal,
        });

        // Decrease stock and log stock movement
        await txn.rawUpdate(
          'UPDATE products SET current_stock = current_stock - ?, updated_at = ? WHERE id = ?',
          [item.quantity, DateTime.now().toIso8601String(), item.productId],
        );
        await txn.insert('stock_movements', {
          'product_id': item.productId,
          'quantity_change': -item.quantity,
          'reason': 'sale',
          'reference_id': txId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return Transaction(
        id: txId,
        invoiceNumber: transaction.invoiceNumber,
        customerId: transaction.customerId,
        totalAmount: transaction.totalAmount,
        discount: transaction.discount,
        tax: transaction.tax,
        finalAmount: transaction.finalAmount,
        paymentMethod: transaction.paymentMethod,
        paymentStatus: transaction.paymentStatus,
        createdAt: transaction.createdAt,
      );
    });
  }

  Future<List<Transaction>> getRecent({int limit = 5}) async {
    final rows = await _db.query(
      'transactions',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<Map<String, Object?>>> getItemsForTransaction(int txId) {
    return _db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [txId],
    );
  }

  Future<double> getSalesTotalForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT SUM(final_amount) as total
      FROM transactions
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final value = rows.first['total'] as num?;
    return value?.toDouble() ?? 0;
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _db.query(
      'transactions',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<Map<DateTime, double>> getDailySalesForLastNDays(int days) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final rows = await _db.rawQuery(
      '''
      SELECT substr(created_at, 1, 10) AS day, SUM(final_amount) AS total
      FROM transactions
      WHERE created_at >= ?
      GROUP BY day
      ORDER BY day ASC
      ''',
      [start.toIso8601String()],
    );
    final Map<DateTime, double> result = {};
    for (final row in rows) {
      final dayStr = row['day'] as String;
      final total = (row['total'] as num).toDouble();
      result[DateTime.parse('${dayStr}T00:00:00')] = total;
    }
    return result;
  }

  Transaction _fromRow(Map<String, Object?> row) {
    return Transaction(
      id: row['id'] as int,
      invoiceNumber: row['invoice_number'] as String,
      customerId: row['customer_id'] as int?,
      totalAmount: (row['total_amount'] as num).toDouble(),
      discount: (row['discount'] as num).toDouble(),
      tax: (row['tax'] as num).toDouble(),
      finalAmount: (row['final_amount'] as num).toDouble(),
      paymentMethod: row['payment_method'] as String,
      paymentStatus: row['payment_status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

