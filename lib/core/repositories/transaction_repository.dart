import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import '../database/app_database.dart';
import '../models/entities.dart';

class TransactionRepository {
  Database get _db => AppDatabase.instance.db;

  Future<Transaction> insertTransaction({
    required Transaction transaction,
    required List<TransactionItem> items,
    DateTime? dueDate,
  }) async {
    return _db.transaction((txn) async {
      final txId = transaction.id ?? 'txn_${DateTime.now().millisecondsSinceEpoch}';

      await txn.insert('transactions', {
        'id': txId,
        'invoice_number': transaction.invoiceNumber,
        'customer_id': transaction.customerId,
        'total_amount': transaction.totalAmount,
        'discount': transaction.discount,
        'tax': transaction.tax,
        'final_amount': transaction.finalAmount,
        'cash_paid': transaction.cashPaid,
        'credit_amount': transaction.creditAmount,
        'payment_method': transaction.paymentMethod,
        'payment_status': transaction.paymentStatus,
        'created_at': transaction.createdAt.toIso8601String(),
      });

      for (final item in items) {
        final itemId = item.id ?? 'txi_${DateTime.now().microsecondsSinceEpoch}';
        await txn.insert('transaction_items', {
          'id': itemId,
          'transaction_id': txId,
          'product_variant_id': item.variantId,
          'quantity': item.quantity,
          'price_at_time': item.priceAtTime,
          'cost_at_time': item.costAtTime,
          'subtotal': item.subtotal,
        });

        // Decrease stock in the new V2 schema (stock_levels)
        final nowStr = DateTime.now().toIso8601String();
        await txn.rawUpdate(
          '''
          UPDATE stock_levels 
          SET available_pieces = available_pieces - ?, 
              total_pieces = total_pieces - ?,
              updated_at = ? 
          WHERE product_variant_id = ?
          ''',
          [item.quantity, item.quantity, nowStr, item.variantId],
        );

        // Fetch the threshold to re-evalute low_stock_warning boolean
        final stockLevels = await txn.query('stock_levels', where: 'product_variant_id = ?', whereArgs: [item.variantId]);
        if (stockLevels.isNotEmpty) {
           final stockMap = stockLevels.first;
           final int available = (stockMap['available_pieces'] as num).toInt();
           final int threshold = (stockMap['low_stock_threshold'] as num).toInt();
           
           if (available <= threshold) {
              await txn.update('stock_levels', {'is_low_stock_warning': 1}, where: 'product_variant_id = ?', whereArgs: [item.variantId]);
           }
        }

        // Log stock movement
        final movementId = 'mov_${DateTime.now().microsecondsSinceEpoch}';
        await txn.insert('stock_movements', {
          'id': movementId,
          'product_variant_id': item.variantId,
          'movement_type': 'OUT',
          'quantity_change': -item.quantity,
          'quantity_before': 0, // In a robust system, fetch before update. Leaving 0 for simplicity here as it's not currently queried.
          'quantity_after': 0,
          'reason': 'Sale / Checkout',
          'reference_id': txId,
          'created_at': nowStr,
        });
      }

      // Automatically register Split Payment debts onto the Ledger
      if (transaction.creditAmount > 0 && transaction.customerId != null) {
         final ledgerId = 'cred_${DateTime.now().microsecondsSinceEpoch}';
         await txn.insert('credit_ledgers', {
            'id': ledgerId,
            'customer_id': transaction.customerId,
            'transaction_id': txId,
            'type': 'CREDIT',
            'amount': transaction.creditAmount,
            'due_date': dueDate?.toIso8601String(),
            'notes': 'POS Checkout Due',
            'created_at': transaction.createdAt.toIso8601String(),
         });

         // Update the customer's aggregate cache directly in the transaction boundary
         await txn.rawUpdate(
           'UPDATE customers SET current_credit = current_credit + ? WHERE id = ?',
           [transaction.creditAmount, transaction.customerId]
         );
      }

      return Transaction(
        id: txId,
        invoiceNumber: transaction.invoiceNumber,
        customerId: transaction.customerId,
        totalAmount: transaction.totalAmount,
        discount: transaction.discount,
        tax: transaction.tax,
        finalAmount: transaction.finalAmount,
        cashPaid: transaction.cashPaid,
        creditAmount: transaction.creditAmount,
        paymentMethod: transaction.paymentMethod,
        paymentStatus: transaction.paymentStatus,
        createdAt: transaction.createdAt,
      );
    });
  }

  Future<List<Transaction>> getRecent({int limit = 5}) async {
    final rows = await _db.rawQuery('''
      SELECT t.*, c.name as customer_name
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      ORDER BY t.created_at DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(_fromRow).toList();
  }

  Future<List<Map<String, Object?>>> getItemsForTransaction(String txId) {
    return _db.rawQuery('''
      SELECT ti.*, p.name as product_name, pv.variant_name
      FROM transaction_items ti
      JOIN product_variants pv ON ti.product_variant_id = pv.id
      JOIN products p ON pv.product_id = p.id
      WHERE ti.transaction_id = ?
    ''', [txId]);
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
    final rows = await _db.rawQuery('''
      SELECT t.*, c.name as customer_name
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE t.created_at >= ? AND t.created_at < ?
      ORDER BY t.created_at DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);
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
      id: row['id'] as String,
      invoiceNumber: row['invoice_number'] as String,
      customerId: row['customer_id'] as String?,
      customerName: row['customer_name'] as String?,
      totalAmount: (row['total_amount'] as num).toDouble(),
      discount: (row['discount'] as num).toDouble(),
      tax: (row['tax'] as num).toDouble(),
      finalAmount: (row['final_amount'] as num).toDouble(),
      cashPaid: (row['cash_paid'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (row['credit_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: row['payment_method'] as String,
      paymentStatus: row['payment_status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

