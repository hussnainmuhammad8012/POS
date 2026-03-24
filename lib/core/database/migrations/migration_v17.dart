import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> migrateToV17(Database db) async {
  // 1. Add reserved_pieces to stock_levels safely
  try {
    await db.execute('ALTER TABLE stock_levels ADD COLUMN reserved_pieces INTEGER DEFAULT 0');
  } catch (e) {
    // Column might already exist if migration was partially successful
    print('Migration v17 Note: reserved_pieces column might already exist.');
  }

  // 2. Create mobile_cart_reservations table
  await db.execute('''
    CREATE TABLE IF NOT EXISTS mobile_cart_reservations (
      id TEXT PRIMARY KEY,
      device_id TEXT NOT NULL,
      product_variant_id TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');

  // 3. Create indices safely
  try {
    await db.execute('CREATE INDEX idx_reservations_device ON mobile_cart_reservations(device_id)');
  } catch (_) {}
  try {
    await db.execute('CREATE INDEX idx_reservations_variant ON mobile_cart_reservations(product_variant_id)');
  } catch (_) {}
}
