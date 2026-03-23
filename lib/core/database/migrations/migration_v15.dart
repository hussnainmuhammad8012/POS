import 'package:sqflite/sqflite.dart';

Future<void> migrateToV15(Database db) async {
  // Add discount_percent to transactions table
  await db.execute('ALTER TABLE transactions ADD COLUMN discount_percent REAL DEFAULT 0.0');
  
  // Add discount_percent to transaction_items table
  await db.execute('ALTER TABLE transaction_items ADD COLUMN discount_percent REAL DEFAULT 0.0');
}
