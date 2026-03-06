import 'package:sqflite/sqflite.dart';

Future<void> migrateToV4(Database db) async {
  print('Starting Migration to V4...');
  try {
    // 1. Alter Customers Table
    // Add whatsapp_number, address, current_credit, credit_limit
    await db.execute('ALTER TABLE customers ADD COLUMN whatsapp_number TEXT');
    await db.execute('ALTER TABLE customers ADD COLUMN address TEXT');
    await db.execute('ALTER TABLE customers ADD COLUMN current_credit REAL DEFAULT 0.0');
    await db.execute('ALTER TABLE customers ADD COLUMN credit_limit REAL DEFAULT 0.0');

    // 2. Alter Transactions Table
    // Add cash_paid, credit_amount
    await db.execute('ALTER TABLE transactions ADD COLUMN cash_paid REAL DEFAULT 0.0');
    await db.execute('ALTER TABLE transactions ADD COLUMN credit_amount REAL DEFAULT 0.0');

    // 3. Create Credit Ledgers Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_ledgers (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        transaction_id TEXT,
        type TEXT NOT NULL, /* 'CREDIT' or 'PAYMENT' */
        amount REAL NOT NULL,
        due_date DATETIME,
        notes TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_credit_ledger_customer ON credit_ledgers(customer_id)');

    // For existing data, initialize the new transaction columns to their final amount to be safe
    await db.execute('UPDATE transactions SET cash_paid = final_amount, credit_amount = 0.0');

    print('Migration to V4 completed successfully!');
  } catch (e, stack) {
    print('CRITICAL ERROR DURING MIGRATION V4: $e');
    print(stack);
    rethrow;
  }
}
