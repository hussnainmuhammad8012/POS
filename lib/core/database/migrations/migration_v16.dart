import 'package:sqflite/sqflite.dart';

Future<void> migrateToV16(Database db) async {
  await db.execute('ALTER TABLE product_units ADD COLUMN tax_rate REAL DEFAULT 0.0');
  await db.execute('ALTER TABLE product_variants ADD COLUMN tax_rate REAL DEFAULT 0.0');
  
  // Add tax_rate and tax_amount to transaction_items table
  await db.execute('ALTER TABLE transaction_items ADD COLUMN tax_rate REAL DEFAULT 0.0');
  await db.execute('ALTER TABLE transaction_items ADD COLUMN tax_amount REAL DEFAULT 0.0');
  
  // Add total_tax and is_tax_inclusive to transactions table
  await db.execute('ALTER TABLE transactions ADD COLUMN total_tax REAL DEFAULT 0.0');
  await db.execute('ALTER TABLE transactions ADD COLUMN is_tax_inclusive INTEGER DEFAULT 0');
}
