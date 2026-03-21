import 'package:sqflite/sqflite.dart';

Future<void> migrateToV13(Database db) async {
  print('Starting Migration to V13 (Stock Movement Unit Tracking)...');
  try {
    // Add unit_id and unit_name to stock_movements
    await db.execute('ALTER TABLE stock_movements ADD COLUMN unit_id TEXT');
    await db.execute('ALTER TABLE stock_movements ADD COLUMN unit_name TEXT');
    
    print('Migration to V13 completed successfully!');
  } catch (e) {
    print('Error during migration V13: $e');
    // Don't rethrow if columns already exist
  }
}
