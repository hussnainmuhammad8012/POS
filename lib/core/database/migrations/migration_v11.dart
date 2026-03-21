import 'package:sqflite/sqflite.dart';

Future<void> migrateToV11(Database db) async {
  print('Starting Migration to V11 (Multi-UOM Support)...');
  try {
    // 1. Create product_units table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_units (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        unit_name TEXT NOT NULL,
        conversion_rate INTEGER NOT NULL DEFAULT 1,
        is_base_unit BOOLEAN DEFAULT 0,
        barcode TEXT UNIQUE,
        qr_code TEXT,
        cost_price REAL NOT NULL,
        retail_price REAL NOT NULL,
        wholesale_price REAL,
        mrp REAL,
        is_active BOOLEAN DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    // 2. Add unit_id and unit_name to transaction_items
    // Use try-catch for altering columns just in case someone manually modified the schema
    try {
      await db.execute('ALTER TABLE transaction_items ADD COLUMN unit_id TEXT');
      await db.execute('ALTER TABLE transaction_items ADD COLUMN unit_name TEXT');
    } catch (e) {
      print('Columns might already exist: $e');
    }

    // 3. Create indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_product_units_product ON product_units(product_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_product_units_barcode ON product_units(barcode)');

    // 4. Migrate existing variants to base units to ensure backwards compatibility
    print('Migrating existing variants to base product_units...');
    await db.execute('''
      INSERT INTO product_units (
        id, product_id, unit_name, conversion_rate, is_base_unit, 
        barcode, qr_code, cost_price, retail_price, wholesale_price, mrp, 
        is_active, created_at, updated_at
      )
      SELECT 
        id || '_unit', 
        product_id, 
        'Piece', 
        1, 
        1, 
        barcode, 
        qr_code, 
        cost_price, 
        retail_price, 
        wholesale_price, 
        mrp, 
        is_active, 
        created_at, 
        updated_at
      FROM product_variants
      WHERE is_active = 1
      ON CONFLICT(id) DO NOTHING
    ''');

    print('Migration to V11 completed successfully!');
  } catch (e, stack) {
    print('CRITICAL ERROR DURING MIGRATION V11: $e');
    print(stack);
    rethrow;
  }
}
