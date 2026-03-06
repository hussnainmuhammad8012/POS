import 'package:sqflite/sqflite.dart';

Future<void> migrateToV3(Database db) async {
  print('Starting Migration to V3...');
  try {
    // Drop the tables to ensure we recreate them with TEXT PRIMARY KEYs
    // These might have been created as INTEGER PRIMARY KEY in older versions
    await db.execute('DROP TABLE IF EXISTS transaction_items');
    await db.execute('DROP TABLE IF EXISTS transactions');
    await db.execute('DROP TABLE IF EXISTS customers');

    // Recreate customers
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        loyalty_points INTEGER DEFAULT 0,
        total_spent REAL DEFAULT 0.0,
        last_purchase_date DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Recreate transactions
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL UNIQUE,
        customer_id TEXT,
        total_amount REAL NOT NULL,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        final_amount REAL NOT NULL,
        payment_method TEXT DEFAULT "CASH",
        payment_status TEXT DEFAULT "COMPLETED",
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
      )
    ''');
    
    // Recreate transaction_items
    await db.execute('''
      CREATE TABLE transaction_items (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        product_variant_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price_at_time REAL NOT NULL,
        cost_at_time REAL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
        FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_customer ON transactions(customer_id)');
    
    print('Migration to V3 completed successfully!');
  } catch (e, stack) {
    print('CRITICAL ERROR DURING MIGRATION V3: $e');
    print(stack);
    rethrow;
  }
}
