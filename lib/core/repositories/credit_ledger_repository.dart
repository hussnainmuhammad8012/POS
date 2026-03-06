import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/app_database.dart';
import '../models/entities.dart';

class CreditLedgerRepository {
  Database get _db => AppDatabase.instance.db;

  Future<List<CreditLedger>> getLedgersByCustomer(String customerId) async {
    final rows = await _db.query(
      'credit_ledgers',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<CreditLedger> insert(CreditLedger ledger) async {
    final id = ledger.id.isEmpty ? 'cred_${DateTime.now().microsecondsSinceEpoch}' : ledger.id;
    
    await _db.insert('credit_ledgers', {
      'id': id,
      'customer_id': ledger.customerId,
      'transaction_id': ledger.transactionId,
      'type': ledger.type,
      'amount': ledger.amount,
      'due_date': ledger.dueDate?.toIso8601String(),
      'notes': ledger.notes,
      'created_at': ledger.createdAt.toIso8601String(),
    });

    final insertedLedger = CreditLedger(
      id: id,
      customerId: ledger.customerId,
      transactionId: ledger.transactionId,
      type: ledger.type,
      amount: ledger.amount,
      dueDate: ledger.dueDate,
      notes: ledger.notes,
      createdAt: ledger.createdAt,
    );

    // Update customer's current credit aggregations
    await _updateCustomerCredit(ledger.customerId);

    return insertedLedger;
  }

  // Recalculates and caches the customer's total outstanding credit
  Future<void> _updateCustomerCredit(String customerId) async {
    final rows = await _db.query(
      'credit_ledgers',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );

    double totalCreditAccumulated = 0;
    double totalPaid = 0;

    for (var row in rows) {
      final type = row['type'] as String;
      final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
      if (type == 'CREDIT') {
        totalCreditAccumulated += amount;
      } else if (type == 'PAYMENT') {
        totalPaid += amount;
      }
    }

    final currentCredit = totalCreditAccumulated - totalPaid;

    await _db.update(
      'customers',
      {'current_credit': currentCredit},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  CreditLedger _fromRow(Map<String, Object?> row) {
    return CreditLedger(
      id: row['id'] as String,
      customerId: row['customer_id'] as String,
      transactionId: row['transaction_id'] as String?,
      type: row['type'] as String,
      amount: (row['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: row['due_date'] != null ? DateTime.parse(row['due_date'] as String) : null,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
