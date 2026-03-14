import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> migrateToV7(Database db) async {
  // Add due_date to supplier_ledgers
  await db.execute('''
    ALTER TABLE supplier_ledgers ADD COLUMN due_date TEXT;
  ''');
}
