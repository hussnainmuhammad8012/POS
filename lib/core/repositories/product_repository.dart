import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/app_database.dart';
import '../models/entities.dart';

class ProductRepository {
  Database get _db => AppDatabase.instance.db;

  Future<Product?> getByBarcode(String barcode) async {
    final rows = await _db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<List<Product>> getAll() async {
    final rows = await _db.query(
      'products',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<Product>> getLowStock() async {
    final rows = await _db.query(
      'products',
      where: 'current_stock <= low_stock_threshold',
      orderBy: 'current_stock ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<Product> insert(Product product) async {
    final id = await _db.insert('products', {
      'barcode': product.barcode,
      'name': product.name,
      'category_id': product.categoryId,
      'selling_price': product.sellingPrice,
      'cost_price': product.costPrice,
      'current_stock': product.currentStock,
      'low_stock_threshold': product.lowStockThreshold,
      'image_path': product.imagePath,
      'created_at': product.createdAt.toIso8601String(),
      'updated_at': product.updatedAt?.toIso8601String(),
    });
    return product.copyWith(id: id);
  }

  Future<Product> update(Product product) async {
    if (product.id == null) {
      throw ArgumentError('Product id is required for update');
    }
    await _db.update(
      'products',
      {
        'barcode': product.barcode,
        'name': product.name,
        'category_id': product.categoryId,
        'selling_price': product.sellingPrice,
        'cost_price': product.costPrice,
        'current_stock': product.currentStock,
        'low_stock_threshold': product.lowStockThreshold,
        'image_path': product.imagePath,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
    return product;
  }

  Future<void> delete(int id) async {
    await _db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> adjustStock({
    required int productId,
    required int quantityChange,
    required String reason,
    int? referenceId,
  }) async {
    await _db.transaction((txn) async {
      final rows = await txn.query(
        'products',
        columns: ['current_stock'],
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Product not found for stock adjustment');
      }
      final current = rows.first['current_stock'] as int;
      final newStock = current + quantityChange;
      await txn.update(
        'products',
        {
          'current_stock': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );
      await txn.insert('stock_movements', {
        'product_id': productId,
        'quantity_change': quantityChange,
        'reason': reason,
        'reference_id': referenceId,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Product _fromRow(Map<String, Object?> row) {
    return Product(
      id: row['id'] as int,
      barcode: row['barcode'] as String?,
      name: row['name'] as String,
      categoryId: row['category_id'] as int?,
      sellingPrice: (row['selling_price'] as num).toDouble(),
      costPrice: (row['cost_price'] as num?)?.toDouble(),
      currentStock: row['current_stock'] as int,
      lowStockThreshold: row['low_stock_threshold'] as int,
      imagePath: row['image_path'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }
}

