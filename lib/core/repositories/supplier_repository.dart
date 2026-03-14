import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/app_database.dart';
import '../models/entities.dart';

class SupplierRepository {
  Database get _db => AppDatabase.instance.db;

  Future<List<Supplier>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT * FROM suppliers 
      ORDER BY name COLLATE NOCASE ASC
    ''');
    return rows.map(_fromRow).toList();
  }

  Future<List<Supplier>> searchSuppliers(String query) async {
    final rows = await _db.rawQuery('''
      SELECT * FROM suppliers 
      WHERE name LIKE ? OR phone LIKE ?
      ORDER BY name COLLATE NOCASE ASC
    ''', ['%$query%', '%$query%']);
    return rows.map(_fromRow).toList();
  }
  
  Future<Supplier?> getById(String id) async {
    final rows = await _db.query('suppliers', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      return _fromRow(rows.first);
    }
    return null;
  }

  Future<Supplier> insert(Supplier supplier) async {
    final id = supplier.id ?? 'sup_${DateTime.now().microsecondsSinceEpoch}';
    final payload = {
      'id': id,
      'name': supplier.name,
      'contact_person': supplier.contactPerson,
      'phone': supplier.phone,
      'email': supplier.email,
      'address': supplier.address,
      'total_purchased': supplier.totalPurchased,
      'current_due': supplier.currentDue,
      'created_at': supplier.createdAt.toIso8601String(),
    };
    await _db.insert('suppliers', payload);
    return supplier.copyWith(id: id);
  }

  Future<Supplier> update(Supplier supplier) async {
    if (supplier.id == null) {
      throw ArgumentError('Supplier id is required for update');
    }
    await _db.update(
      'suppliers',
      {
        'name': supplier.name,
        'contact_person': supplier.contactPerson,
        'phone': supplier.phone,
        'email': supplier.email,
        'address': supplier.address,
        'total_purchased': supplier.totalPurchased,
        'current_due': supplier.currentDue,
      },
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
    return supplier;
  }

  Future<void> delete(String id) async {
    await _db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- LEDGER OPERATIONS ---

  Future<List<SupplierLedger>> getLedger(String supplierId) async {
    final rows = await _db.query(
      'supplier_ledgers',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'created_at DESC',
    );
    return rows.map(_ledgerFromRow).toList();
  }

  Future<void> addLedgerEntry(SupplierLedger entry) async {
    await _db.transaction((txn) async {
      // 1. Insert Ledger
      await txn.insert('supplier_ledgers', {
        'id': entry.id,
        'supplier_id': entry.supplierId,
        'reference_id': entry.referenceId,
        'type': entry.type,
        'amount': entry.amount,
        'due_date': entry.dueDate?.toIso8601String(),
        'notes': entry.notes,
        'created_at': entry.createdAt.toIso8601String(),
      });

      // 2. Update Supplier Totals if Purchase or Payment
      if (entry.type == 'PURCHASE') {
        await txn.rawUpdate('''
          UPDATE suppliers 
          SET total_purchased = total_purchased + ?,
              current_due = current_due + ?
          WHERE id = ?
        ''', [entry.amount, entry.amount, entry.supplierId]);
      } else if (entry.type == 'PAYMENT') {
        await txn.rawUpdate('''
          UPDATE suppliers 
          SET current_due = current_due - ?
          WHERE id = ?
        ''', [entry.amount, entry.supplierId]);
      }
    });
  }

  // --- MAPPERS ---

  Supplier _fromRow(Map<String, Object?> row) {
    return Supplier(
      id: row['id'] as String?,
      name: row['name'] as String,
      contactPerson: row['contact_person'] as String?,
      phone: row['phone'] as String?,
      email: row['email'] as String?,
      address: row['address'] as String?,
      totalPurchased: (row['total_purchased'] as num?)?.toDouble() ?? 0.0,
      currentDue: (row['current_due'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  SupplierLedger _ledgerFromRow(Map<String, Object?> row) {
    return SupplierLedger(
      id: row['id'] as String,
      supplierId: row['supplier_id'] as String,
      referenceId: row['reference_id'] as String?,
      type: row['type'] as String,
      amount: (row['amount'] as num).toDouble(),
      dueDate: row['due_date'] != null ? DateTime.parse(row['due_date'] as String) : null,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
