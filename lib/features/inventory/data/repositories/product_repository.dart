// lib/features/inventory/data/repositories/product_repository.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/product_model.dart';
import '../models/product_variant_model.dart';
import '../models/stock_level_model.dart';

class ProductRepository {
  final AppDatabase database;

  ProductRepository({required this.database});

  Database get _db => database.database;

  // Create product
  Future<String> createProduct({
    required String categoryId,
    required String name,
    required String baseSku,
    String? description,
    String? mainImagePath,
    required String unitType,
  }) async {
    final id = 'prod_${DateTime.now().millisecondsSinceEpoch}';
    await _db.insert('products', {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'base_sku': baseSku,
      'main_image_path': mainImagePath,
      'unit_type': unitType,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  // Create product variant with pricing
  Future<String> createProductVariant({
    required String productId,
    String? variantName,
    required String sku,
    String? barcode,
    required double costPrice,
    required double retailPrice,
    double? wholesalePrice,
    double? mrp,
    String? variantImagePath,
    int initialStock = 0,
    int lowStockThreshold = 10,
  }) async {
    final id = 'var_${DateTime.now().millisecondsSinceEpoch}';
    await _db.insert('product_variants', {
      'id': id,
      'product_id': productId,
      'variant_name': variantName,
      'sku': sku,
      'barcode': barcode,
      'cost_price': costPrice,
      'retail_price': retailPrice,
      'wholesale_price': wholesalePrice,
      'mrp': mrp,
      'variant_image_path': variantImagePath,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Auto-create stock level entry
    await _createStockLevel(id, initialStock, lowStockThreshold);

    return id;
  }

  // Get all products
  Future<List<Product>> getAllProducts({
    String? categoryId,
    String? searchQuery,
    bool includeInactive = false,
  }) async {
    String query = 'SELECT * FROM products WHERE 1=1';
    List<dynamic> args = [];

    if (!includeInactive) {
      query += ' AND is_active = 1';
    }

    if (categoryId != null) {
      query += ' AND category_id = ?';
      args.add(categoryId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' AND (name LIKE ? OR base_sku LIKE ?)';
      final searchPattern = '%$searchQuery%';
      args.addAll([searchPattern, searchPattern]);
    }

    query += ' ORDER BY name ASC';

    final result = await _db.rawQuery(query, args);
    return [for (var json in result) Product.fromJson(json)];
  }

  // Get product with all variants
  Future<Map<String, dynamic>?> getProductWithVariants(String productId) async {
    final productResult = await _db.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (productResult.isEmpty) return null;

    final variants = await _db.query(
      'product_variants',
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    return {
      'product': Product.fromJson(productResult.first),
      'variants': [for (var v in variants) ProductVariant.fromJson(v)],
    };
  }

  // Get variant by barcode
  Future<ProductVariant?> getVariantByBarcode(String barcode) async {
    final result = await _db.query(
      'product_variants',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode],
    );

    if (result.isEmpty) return null;
    return ProductVariant.fromJson(result.first);
  }

  // Update variant pricing
  Future<void> updateVariantPricing({
    required String variantId,
    double? costPrice,
    double? retailPrice,
    double? wholesalePrice,
    double? mrp,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (costPrice != null) updates['cost_price'] = costPrice;
    if (retailPrice != null) updates['retail_price'] = retailPrice;
    if (wholesalePrice != null) updates['wholesale_price'] = wholesalePrice;
    if (mrp != null) updates['mrp'] = mrp;

    await _db.update(
      'product_variants',
      updates,
      where: 'id = ?',
      whereArgs: [variantId],
    );
  }

  // Soft delete product
  Future<void> deleteProduct(String productId) async {
    await _db.update(
      'products',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Private helper to create stock level
  Future<void> _createStockLevel(String variantId, int initialStock, int threshold) async {
    final id = 'stk_${DateTime.now().millisecondsSinceEpoch}';
    await _db.insert('stock_levels', {
      'id': id,
      'product_variant_id': variantId,
      'total_pieces': initialStock,
      'total_cartons': 0,
      'reserved_pieces': 0,
      'available_pieces': initialStock,
      'low_stock_threshold': threshold,
      'reorder_point': threshold * 2,
      'is_low_stock_warning': initialStock <= threshold ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
