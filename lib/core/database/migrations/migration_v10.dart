import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> migrateToV10(Database db) async {
  // Create settings table if not exists
  await db.execute('''
    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');

  // We don't insert the license key here, it will be done via UI
}
