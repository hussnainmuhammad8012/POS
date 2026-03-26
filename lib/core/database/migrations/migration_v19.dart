import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> migrateToV19(Database db) async {
  // Alter transactions table to add return fields
  try {
    await db.execute(
        'ALTER TABLE transactions ADD COLUMN is_returned INTEGER NOT NULL DEFAULT 0');
  } catch (e) {
    print('Column is_returned already exists or error: $e');
  }

  try {
    await db.execute(
        'ALTER TABLE transactions ADD COLUMN returned_amount REAL NOT NULL DEFAULT 0.0');
  } catch (e) {
    print('Column returned_amount already exists or error: $e');
  }

  // Alter transaction_items table to add returned quantity field
  try {
    await db.execute(
        'ALTER TABLE transaction_items ADD COLUMN returned_quantity INTEGER NOT NULL DEFAULT 0');
  } catch (e) {
    print('Column returned_quantity already exists or error: $e');
  }
}
