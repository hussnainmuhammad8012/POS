import 'package:sqflite/sqflite.dart';

Future<void> migrateToV14(Database db) async {
  print('Starting Migration to V14 (Transaction Item Discounts)...');
  try {
    // Add discount column to transaction_items
    await db.execute('ALTER TABLE transaction_items ADD COLUMN discount REAL DEFAULT 0.0');
    
    print('Migration to V14 completed successfully!');
  } catch (e) {
    print('Error during migration V14: $e');
    // Don't rethrow if column already exists
  }
}
