import 'package:sqflite/sqflite.dart';

Future<void> migrateToV2(Database db) async {
  print('Starting Migration to V2...');
  try {
    // 1. Create hierarchical categories table
    print('Dropping and recreating categories table...');
    await db.execute('DROP TABLE IF EXISTS categories');
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        parent_id TEXT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        icon_name TEXT,
        display_order INTEGER DEFAULT 0,
        is_active BOOLEAN DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    // 2. Create products table (replace if exists)
    print('Recreating products table...');
    await db.execute('DROP TABLE IF EXISTS products');
    
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        base_sku TEXT UNIQUE,
        main_image_path TEXT,
        unit_type TEXT NOT NULL,
        is_active BOOLEAN DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
      )
    ''');

    // 3. Product variants table
    print('Creating product_variants table...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_variants (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        variant_name TEXT,
        sku TEXT NOT NULL UNIQUE,
        barcode TEXT UNIQUE,
        cost_price REAL NOT NULL,
        retail_price REAL NOT NULL,
        wholesale_price REAL,
        mrp REAL,
        variant_image_path TEXT,
        is_active BOOLEAN DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    // 4. Cartons table
    print('Creating cartons table...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cartons (
        id TEXT PRIMARY KEY,
        product_variant_id TEXT NOT NULL,
        carton_number TEXT NOT NULL,
        pieces_per_carton INTEGER NOT NULL,
        cost_per_piece REAL NOT NULL,
        carton_cost REAL NOT NULL,
        received_quantity INTEGER NOT NULL,
        available_quantity INTEGER NOT NULL,
        opened_date DATETIME,
        is_opened BOOLEAN DEFAULT 0,
        expiry_date DATETIME,
        supplier_batch_id TEXT,
        storage_location TEXT,
        notes TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE
      )
    ''');

    // 5. Stock levels table
    print('Creating stock_levels table...');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_levels (
        id TEXT PRIMARY KEY,
        product_variant_id TEXT NOT NULL UNIQUE,
        total_pieces INTEGER DEFAULT 0,
        total_cartons INTEGER DEFAULT 0,
        reserved_pieces INTEGER DEFAULT 0,
        available_pieces INTEGER DEFAULT 0,
        low_stock_threshold INTEGER DEFAULT 10,
        reorder_point INTEGER DEFAULT 20,
        is_low_stock_warning BOOLEAN DEFAULT 0,
        last_counted_at DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE
      )
    ''');

    // 6. Stock movements table
    print('Dropping and recreating stock_movements table...');
    await db.execute('DROP TABLE IF EXISTS stock_movements');
    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        product_variant_id TEXT NOT NULL,
        carton_id TEXT,
        movement_type TEXT NOT NULL,
        quantity_change INTEGER NOT NULL,
        quantity_before INTEGER NOT NULL,
        quantity_after INTEGER NOT NULL,
        reason TEXT NOT NULL,
        reference_id TEXT,
        notes TEXT,
        recorded_by TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE,
        FOREIGN KEY (carton_id) REFERENCES cartons(id) ON DELETE SET NULL
      )
    ''');

    // 7. Update transactions table
    print('Updating transactions table...');
    try {
      await db.execute('ALTER TABLE transactions ADD COLUMN payment_method TEXT DEFAULT "CASH"');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE transactions ADD COLUMN payment_status TEXT DEFAULT "COMPLETED"');
    } catch (_) {}

    // 8. Create indexes
    print('Creating indexes...');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_variants_product ON product_variants(product_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_variants_barcode ON product_variants(barcode)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cartons_variant ON cartons(product_variant_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_levels_variant ON stock_levels(product_variant_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_movements_variant ON stock_movements(product_variant_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_customer ON transactions(customer_id)');
    
    print('Migration to V2 completed successfully!');
  } catch (e, stack) {
    print('CRITICAL ERROR DURING MIGRATION: $e');
    print(stack);
    rethrow;
  }
}
