import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/app_database.dart';
import '../models/entities.dart';

class CustomerRepository {
  Database get _db => AppDatabase.instance.db;

  Future<List<Customer>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT 
        c.*, 
        COALESCE(SUM(t.final_amount), 0) as total_spent 
      FROM customers c 
      LEFT JOIN transactions t ON c.id = t.customer_id 
      GROUP BY c.id 
      ORDER BY c.name COLLATE NOCASE ASC
    ''');
    return rows.map(_fromRow).toList();
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final rows = await _db.rawQuery('''
      SELECT 
        c.*, 
        COALESCE(SUM(t.final_amount), 0) as total_spent 
      FROM customers c 
      LEFT JOIN transactions t ON c.id = t.customer_id 
      WHERE c.name LIKE ? OR c.phone LIKE ?
      GROUP BY c.id 
      ORDER BY c.name COLLATE NOCASE ASC
    ''', ['%$query%', '%$query%']);
    return rows.map(_fromRow).toList();
  }

  Future<Customer> insert(Customer customer) async {
    final id = customer.id ?? 'cust_${DateTime.now().microsecondsSinceEpoch}';
    final payload = {
      'id': id,
      'name': customer.name,
      'phone': customer.phone,
      'whatsapp_number': customer.whatsappNumber,
      'address': customer.address,
      'email': customer.email,
      'loyalty_points': customer.loyaltyPoints,
      'total_spent': customer.totalSpent,
      'current_credit': customer.currentCredit,
      'credit_limit': customer.creditLimit,
      'last_purchase_date': customer.lastPurchaseDate?.toIso8601String(),
      'created_at': customer.createdAt.toIso8601String(),
    };
    await _db.insert('customers', payload);
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
        'whatsapp_number': customer.whatsappNumber,
        'address': customer.address,
        'email': customer.email,
        'loyalty_points': customer.loyaltyPoints,
        'total_spent': customer.totalSpent,
        'current_credit': customer.currentCredit,
        'credit_limit': customer.creditLimit,
        'last_purchase_date': customer.lastPurchaseDate?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    return customer;
  }

  Future<void> delete(String id) async {
    await _db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Customer _fromRow(Map<String, Object?> row) {
    return Customer(
      id: row['id'] as String?,
      name: row['name'] as String,
      phone: row['phone'] as String?,
      whatsappNumber: row['whatsapp_number'] as String?,
      address: row['address'] as String?,
      email: row['email'] as String?,
      loyaltyPoints: (row['loyalty_points'] as num?)?.toInt() ?? 0,
      totalSpent: (row['total_spent'] as num?)?.toDouble() ?? 0.0,
      currentCredit: (row['current_credit'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (row['credit_limit'] as num?)?.toDouble() ?? 0.0,
      lastPurchaseDate: row['last_purchase_date'] != null
          ? DateTime.parse(row['last_purchase_date'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

