import 'package:sqflite/sqflite.dart';

Future<void> migrateToV6(Database db) async {
  print('Starting Migration to V6...');
  try {
    // 1. Create Suppliers Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        contact_person TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        total_purchased REAL DEFAULT 0.0,
        current_due REAL DEFAULT 0.0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // 2. Create Supplier Ledgers Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplier_ledgers (
        id TEXT PRIMARY KEY,
        supplier_id TEXT NOT NULL,
        reference_id TEXT,
        type TEXT NOT NULL, /* 'PURCHASE', 'PAYMENT', or 'SYSTEM_NOTE' */
        amount REAL NOT NULL,
        notes TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_supplier_ledger_supplier ON supplier_ledgers(supplier_id)');

    // 3. Alter Products Table
    // We add supplier_id to track the default supplier for a product
    await db.execute('ALTER TABLE products ADD COLUMN supplier_id TEXT REFERENCES suppliers(id) ON DELETE SET NULL');
    
    // 4. Alter Cartons Table
    // We add supplier_id to track which supplier provided a specific carton/batch
    await db.execute('ALTER TABLE cartons ADD COLUMN supplier_id TEXT REFERENCES suppliers(id) ON DELETE SET NULL');

    print('Migration to V6 completed successfully!');
  } catch (e, stack) {
    print('CRITICAL ERROR DURING MIGRATION V6: $e');
    print(stack);
    rethrow;
  }
}
