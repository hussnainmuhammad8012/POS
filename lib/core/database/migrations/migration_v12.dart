import 'package:sqflite/sqflite.dart';

Future<void> migrateToV12(Database db) async {
  print('Starting Migration to V12 (Ensuring Schema Integrity)...');
  try {
    // Check if qr_code column exists in product_units
    final List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(product_units)');
    
    bool hasQrCode = false;
    for (final col in columns) {
      if (col['name'] == 'qr_code') {
        hasQrCode = true;
        break;
      }
    }

    if (!hasQrCode) {
      print('Adding missing qr_code column to product_units...');
      await db.execute('ALTER TABLE product_units ADD COLUMN qr_code TEXT');
    }

    print('Migration to V12 completed successfully!');
  } catch (e, stack) {
    print('Error during migration V12: $e');
    print(stack);
    // Don't rethrow if it's just a "duplicate column" error from a race condition, 
    // though the PRAGMA check should prevent that.
  }
}
