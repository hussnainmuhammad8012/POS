import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> migrateToV9(Database db) async {
  await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      role TEXT NOT NULL,
      canAccessPos INTEGER DEFAULT 0,
      canAccessInventory INTEGER DEFAULT 0,
      canAccessCustomers INTEGER DEFAULT 0,
      canAccessSuppliers INTEGER DEFAULT 0,
      canAccessTransactions INTEGER DEFAULT 0,
      canAccessCredits INTEGER DEFAULT 0,
      canAccessDues INTEGER DEFAULT 0,
      canAccessAnalytics INTEGER DEFAULT 0,
      canAccessSettings INTEGER DEFAULT 0
    )
  ''');

  // Insert default accounts
  await db.insert('users', {
    'username': 'admin',
    'password': 'admin123', // User can change this later
    'role': 'admin',
    'canAccessPos': 1,
    'canAccessInventory': 1,
    'canAccessCustomers': 1,
    'canAccessSuppliers': 1,
    'canAccessTransactions': 1,
    'canAccessCredits': 1,
    'canAccessDues': 1,
    'canAccessAnalytics': 1,
    'canAccessSettings': 1,
  });

  await db.insert('users', {
    'username': 'pos',
    'password': 'pos123',
    'role': 'pos',
    'canAccessPos': 1,
    'canAccessInventory': 0,
    'canAccessCustomers': 1,
    'canAccessSuppliers': 0,
    'canAccessTransactions': 0,
    'canAccessCredits': 0,
    'canAccessDues': 0,
    'canAccessAnalytics': 0,
    'canAccessSettings': 0,
  });

  await db.insert('users', {
    'username': 'inventory',
    'password': 'inv123',
    'role': 'inventoryManager',
    'canAccessPos': 0,
    'canAccessInventory': 1,
    'canAccessCustomers': 0,
    'canAccessSuppliers': 1,
    'canAccessTransactions': 0,
    'canAccessCredits': 0,
    'canAccessDues': 1,
    'canAccessAnalytics': 0,
    'canAccessSettings': 0,
  });
}
