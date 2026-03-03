import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Centralized SQLite database initialization and access.
///
/// Uses `sqflite_common_ffi` so it works on Windows/macOS/Linux without a
/// separate database server.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  late Database _db;
  bool _initialized = false;

  Database get db {
    if (!_initialized) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _db;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;

    final appDataDir = await _resolveAppDataDirectory();
    final dbPath = p.join(appDataDir.path, 'utility_store_pos.db');

    _db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await _createSchema(db);
        },
      ),
    );

    _initialized = true;
  }

  Future<Directory> _resolveAppDataDirectory() async {
    // For a simple single-user desktop app we store data alongside the exe/folder.
    // In a more advanced setup, this could be moved to %APPDATA% on Windows.
    final currentDir = Directory.current;
    final dataDir = Directory(p.join(currentDir.path, 'data'));
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return dataDir;
  }

  Future<void> _createSchema(Database db) async {
    // categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        icon_name TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    // products
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT UNIQUE,
        name TEXT NOT NULL,
        category_id INTEGER,
        selling_price REAL NOT NULL,
        cost_price REAL,
        current_stock INTEGER NOT NULL DEFAULT 0,
        low_stock_threshold INTEGER NOT NULL DEFAULT 5,
        image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      );
    ''');

    // customers
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        loyalty_points INTEGER NOT NULL DEFAULT 0,
        total_spent REAL NOT NULL DEFAULT 0,
        last_purchase_date TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    // transactions
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER,
        total_amount REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        tax REAL NOT NULL DEFAULT 0,
        final_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      );
    ''');

    // transaction_items
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price_at_time REAL NOT NULL,
        cost_at_time REAL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      );
    ''');

    // stock_movements
    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity_change INTEGER NOT NULL,
        reason TEXT NOT NULL,
        reference_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id)
      );
    ''');

    // settings (store info, appearance, etc.)
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');
  }
}

