import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/app_database.dart';
import '../models/entities.dart';

class CustomerRepository {
  Database get _db => AppDatabase.instance.db;

  Future<List<Customer>> getAll() async {
    final rows = await _db.query(
      'customers',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<Customer> insert(Customer customer) async {
    final id = await _db.insert('customers', {
      'name': customer.name,
      'phone': customer.phone,
      'email': customer.email,
      'loyalty_points': customer.loyaltyPoints,
      'total_spent': customer.totalSpent,
      'last_purchase_date': customer.lastPurchaseDate?.toIso8601String(),
      'created_at': customer.createdAt.toIso8601String(),
    });
    return customer.copyWith(id: id);
  }

  Future<Customer> update(Customer customer) async {
    if (customer.id == null) {
      throw ArgumentError('Customer id is required for update');
    }
    await _db.update(
      'customers',
      {
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email,
        'loyalty_points': customer.loyaltyPoints,
        'total_spent': customer.totalSpent,
        'last_purchase_date':
            customer.lastPurchaseDate?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    return customer;
  }

  Customer _fromRow(Map<String, Object?> row) {
    return Customer(
      id: row['id'] as int,
      name: row['name'] as String,
      phone: row['phone'] as String?,
      email: row['email'] as String?,
      loyaltyPoints: row['loyalty_points'] as int,
      totalSpent: (row['total_spent'] as num).toDouble(),
      lastPurchaseDate: row['last_purchase_date'] != null
          ? DateTime.parse(row['last_purchase_date'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

