import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> migrateToV8(Database db) async {
  // Add qr_code to product_variants
  await db.execute('''
    ALTER TABLE product_variants ADD COLUMN qr_code TEXT;
  ''');
}
