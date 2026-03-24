import 'package:sqflite/sqflite.dart';

Future<void> migrateToV18(Database db) async {
  print('Starting Migration to V18 (Adding QR Code Indices)...');
  
  // 1. Add index to product_units(qr_code)
  try {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_product_units_qr_code ON product_units(qr_code)');
  } catch (e) {
    print('Migration v18 Error (product_units index): $e');
  }

  // 2. Add index to product_variants(qr_code)
  try {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_product_variants_qr_code ON product_variants(qr_code)');
  } catch (e) {
    print('Migration v18 Error (product_variants index): $e');
  }

  print('Migration to V18 completed.');
}
