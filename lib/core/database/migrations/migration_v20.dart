import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> migrateV20(Database db) async {
  await db.execute('''
    CREATE TABLE return_events (
      id TEXT PRIMARY KEY,
      transaction_id TEXT NOT NULL,
      refund_amount REAL NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (transaction_id) REFERENCES transactions (id)
    )
  ''');
  
  // Backfill existing returns from transactions table
  // Assuming the return happened at the exact same time as the invoice generation for older untracked data.
  await db.execute('''
    INSERT INTO return_events (id, transaction_id, refund_amount, created_at)
    SELECT id || '_ret_mig', id, returned_amount, created_at
    FROM transactions
    WHERE returned_amount > 0
  ''');
}
