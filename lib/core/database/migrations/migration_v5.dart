import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> migrateToV5(Database db) async {
  // Add notifications table
  await db.execute('''
    CREATE TABLE notifications (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      message TEXT NOT NULL,
      type TEXT NOT NULL, -- e.g., 'CREDIT_REMINDER', 'LOW_STOCK'
      payload TEXT, -- JSON for navigation or extra data
      is_read INTEGER DEFAULT 0,
      created_at TEXT NOT NULL
    )
  ''');
  
  // Add due_date to credit_ledgers if not exists (it was optional in previous model view, but let's ensure it's in the DB)
  // Checking if column exists first to avoid errors on some SQLite versions
  final tableInfo = await db.rawQuery('PRAGMA table_info(credit_ledgers)');
  final hasDueDate = tableInfo.any((column) => column['name'] == 'due_date');
  
  if (!hasDueDate) {
    await db.execute('ALTER TABLE credit_ledgers ADD COLUMN due_date TEXT');
  }
}
