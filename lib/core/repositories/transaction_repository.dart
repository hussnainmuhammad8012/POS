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
        'discount_percent': transaction.discountPercent,
        'tax': transaction.tax,
        'is_tax_inclusive': transaction.isTaxInclusive ? 1 : 0,
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
          'discount': item.discount,
          'discount_percent': item.discountPercent,
          'tax_rate': item.taxRate,
          'tax_amount': item.taxAmount,
          'unit_id': item.unitId,       // UOM: null for classic items
          'unit_name': item.unitName,   // UOM: null for classic items
        });

        // Safety Check: Ensure enough stock exists before deducting
        final currentStockRows = await txn.query('stock_levels', columns: ['available_pieces'], where: 'product_variant_id = ?', whereArgs: [item.variantId]);
        if (currentStockRows.isNotEmpty) {
          final currentAvailable = (currentStockRows.first['available_pieces'] as num).toInt();
          if (currentAvailable < item.quantity) {
             throw Exception('Insufficient stock for variant ${item.variantId}. Available: $currentAvailable, Required: ${item.quantity}');
          }
        }

        // Decrease stock in the new V2 schema (stock_levels)
        final nowStr = DateTime.now().toIso8601String();
        String currentVariantId = item.variantId;
        int updateResult = await txn.rawUpdate(
          '''
          UPDATE stock_levels 
          SET available_pieces = available_pieces - ?, 
              total_pieces = total_pieces - ?,
              updated_at = ? 
          WHERE product_variant_id = ?
          ''',
          [item.quantity, item.quantity, nowStr, currentVariantId],
        );

        if (updateResult == 0 && currentVariantId.contains('__')) {
          // Robust Fallback: If composite ID (mobile format) wasn't found, 
          // extract the product ID and target the primary variant directly.
          final pid = currentVariantId.split('__').first;
          print('DB Fallback: Resolving primary variant for product $pid...');
          
          final vResults = await txn.query('product_variants', 
            columns: ['id'], 
            where: 'product_id = ? AND is_active = 1', 
            whereArgs: [pid], 
            limit: 1
          );

          if (vResults.isNotEmpty) {
            final primaryId = vResults.first['id'] as String;
            print('DB Fallback: Redirecting deduction to primary variant $primaryId');
            currentVariantId = primaryId; // Update for subsequent checks/logs
            updateResult = await txn.rawUpdate(
              '''
              UPDATE stock_levels 
              SET available_pieces = available_pieces - ?, 
                  total_pieces = total_pieces - ?,
                  updated_at = ? 
              WHERE product_variant_id = ?
              ''',
              [item.quantity, item.quantity, nowStr, currentVariantId],
            );
          }
        }
        
        print('DB: Update result for $currentVariantId: $updateResult row(s) affected');

        // Fetch the threshold to re-evalute low_stock_warning boolean
        final stockLevels = await txn.query('stock_levels', where: 'product_variant_id = ?', whereArgs: [currentVariantId]);
        if (stockLevels.isNotEmpty) {
           final stockMap = stockLevels.first;
           final int available = (stockMap['available_pieces'] as num).toInt();
           final int threshold = (stockMap['low_stock_threshold'] as num).toInt();
           
           if (available <= threshold) {
              await txn.update('stock_levels', {'is_low_stock_warning': 1}, where: 'product_variant_id = ?', whereArgs: [currentVariantId]);
           }
        }

        // Log stock movement
        final movementId = 'mov_${DateTime.now().microsecondsSinceEpoch}';
        await txn.insert('stock_movements', {
          'id': movementId,
          'product_variant_id': currentVariantId,
          'movement_type': 'OUT',
          'quantity_change': -item.quantity,
          'quantity_before': 0, 
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
        isTaxInclusive: transaction.isTaxInclusive,
        finalAmount: transaction.finalAmount,
        cashPaid: transaction.cashPaid,
        creditAmount: transaction.creditAmount,
        paymentMethod: transaction.paymentMethod,
        paymentStatus: transaction.paymentStatus,
        createdAt: transaction.createdAt,
        discountPercent: transaction.discountPercent,
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
      SELECT ti.*, 
             ti.discount as item_discount,
             ti.discount_percent as item_discount_percent,
             COALESCE(p1.name, p2.name) as product_name,
             COALESCE(p1.base_sku, p2.base_sku) as product_sku,
             COALESCE(pv.variant_name, pu.unit_name) as variant_name
      FROM transaction_items ti
      LEFT JOIN product_variants pv ON ti.product_variant_id = pv.id
      LEFT JOIN products p1 ON pv.product_id = p1.id
      LEFT JOIN product_units pu ON ti.product_variant_id = pu.id
      LEFT JOIN products p2 ON pu.product_id = p2.id
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

  Future<Transaction?> getTransactionById(String id) async {
    final rows = await _db.rawQuery('''
      SELECT t.*, c.name as customer_name
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE t.id = ?
    ''', [id]);
    
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
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
      discountPercent: (row['discount_percent'] as num?)?.toDouble() ?? 0.0,
      tax: (row['tax'] as num).toDouble(),
      isTaxInclusive: row['is_tax_inclusive'] == 1,
      finalAmount: (row['final_amount'] as num).toDouble(),
      cashPaid: (row['cash_paid'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (row['credit_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: row['payment_method'] as String,
      paymentStatus: row['payment_status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

