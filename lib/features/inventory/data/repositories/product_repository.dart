// lib/features/inventory/data/repositories/product_repository.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/product_model.dart';
import '../models/product_summary_model.dart';
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

  // Update product, its primary variant, and its stock level
  Future<void> updateProduct(String id, {
    String? categoryId,
    String? name,
    String? baseSku,
    String? description,
    String? mainImagePath,
    String? unitType,
    double? costPrice,
    double? retailPrice,
    double? wholesalePrice,
    double? mrp,
    String? barcode,
    int? initialStock,
    int? lowStockThreshold,
  }) async {
    await _db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      
      // 1. Update Product
      final pUpdates = <String, dynamic>{'updated_at': now};
      if (categoryId != null) pUpdates['category_id'] = categoryId;
      if (name != null) pUpdates['name'] = name;
      if (baseSku != null) pUpdates['base_sku'] = baseSku;
      if (description != null) pUpdates['description'] = description;
      if (mainImagePath != null) pUpdates['main_image_path'] = mainImagePath;
      if (unitType != null) pUpdates['unit_type'] = unitType;

      await txn.update('products', pUpdates, where: 'id = ?', whereArgs: [id]);

      // 2. Find default variant to update
      final variants = await txn.query(
        'product_variants',
        where: 'product_id = ? AND is_active = 1',
        whereArgs: [id],
      );

      if (variants.isNotEmpty) {
        final variantId = variants.first['id'] as String;

        // 3. Update Variant Pricing & Barcode
        final vUpdates = <String, dynamic>{'updated_at': now};
        if (costPrice != null) vUpdates['cost_price'] = costPrice;
        if (retailPrice != null) vUpdates['retail_price'] = retailPrice;
        if (wholesalePrice != null) vUpdates['wholesale_price'] = wholesalePrice;
        if (mrp != null) vUpdates['mrp'] = mrp;
        if (barcode != null) vUpdates['barcode'] = barcode;

        if (vUpdates.length > 1) {
          await txn.update('product_variants', vUpdates, where: 'id = ?', whereArgs: [variantId]);
        }

        // 4. Update Stock Level
        final sUpdates = <String, dynamic>{'updated_at': now};
        if (initialStock != null) {
          sUpdates['total_pieces'] = initialStock;
          sUpdates['available_pieces'] = initialStock;
          // In a complex system, altering 'initial' stock wouldn't blindly overwrite 
          // available pieces, but it works for this simplified model update path.
        }
        if (lowStockThreshold != null) {
          sUpdates['low_stock_threshold'] = lowStockThreshold;
        }

        if (sUpdates.length > 1) {
          // Fetch current stock to see if threshold is broken and log diffments
          final stocks = await txn.query('stock_levels', where: 'product_variant_id = ?', whereArgs: [variantId]);
          int prevStock = 0;
          
          if (stocks.isNotEmpty) {
             prevStock = (stocks.first['available_pieces'] as int?) ?? 0;
             final int currStock = initialStock ?? prevStock;
             final int currThreshold = lowStockThreshold ?? (stocks.first['low_stock_threshold'] as int?) ?? 0;
             sUpdates['is_low_stock_warning'] = currStock <= currThreshold ? 1 : 0;
          }

          if (initialStock != null && initialStock != prevStock) {
             final int diff = initialStock - prevStock;
             await txn.insert('stock_movements', {
               'id': 'mov_${DateTime.now().microsecondsSinceEpoch}',
               'product_variant_id': variantId,
               'movement_type': diff > 0 ? 'ADJUSTMENT' : 'OUT',
               'quantity_change': diff,
               'quantity_before': prevStock,
               'quantity_after': initialStock,
               'reason': 'Manual Adjustment from Product Form',
               'created_at': now,
             });
          }

          await txn.update('stock_levels', sUpdates, where: 'product_variant_id = ?', whereArgs: [variantId]);
        }
      }
    });
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

  // Get aggregated product summaries
  Future<List<ProductSummary>> getAllProductSummaries({
    String? categoryId,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    int? minStock,
    int? maxStock,
    bool showLowStockOnly = false,
  }) async {
    String query = '''
      SELECT 
        p.*,
        c.name as category_name,
        MIN(v.retail_price) as min_price,
        MAX(v.retail_price) as max_price,
        MIN(v.cost_price) as cost_price,
        MIN(v.wholesale_price) as wholesale_price,
        MIN(v.mrp) as mrp,
        MAX(v.barcode) as barcode,
        SUM(s.available_pieces) as total_stock,
        MAX(s.low_stock_threshold) as low_stock_threshold,
        MAX(s.is_low_stock_warning) as is_low_stock_warning
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN product_variants v ON p.id = v.product_id AND v.is_active = 1
      LEFT JOIN stock_levels s ON v.id = s.product_variant_id
      WHERE p.is_active = 1
    ''';

    List<dynamic> args = [];

    if (categoryId != null) {
      query += ' AND p.category_id = ?';
      args.add(categoryId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' AND (p.name LIKE ? OR p.base_sku LIKE ?)';
      final searchPattern = '%$searchQuery%';
      args.addAll([searchPattern, searchPattern]);
    }

    query += ' GROUP BY p.id HAVING 1=1';

    if (minPrice != null) {
      query += ' AND min_price >= ?';
      args.add(minPrice);
    }

    if (maxPrice != null) {
      query += ' AND max_price <= ?';
      args.add(maxPrice);
    }

    if (minStock != null) {
      query += ' AND total_stock >= ?';
      args.add(minStock);
    }

    if (maxStock != null) {
      query += ' AND total_stock <= ?';
      args.add(maxStock);
    }

    if (showLowStockOnly) {
      query += ' AND is_low_stock_warning = 1';
    }

    query += ' ORDER BY p.name ASC';

    final result = await _db.rawQuery(query, args);
    
    return result.map((row) {
      final product = Product.fromJson(row);
      return ProductSummary(
        product: product,
        categoryName: row['category_name'] as String?,
        minPrice: (row['min_price'] as num?)?.toDouble() ?? 0.0,
        maxPrice: (row['max_price'] as num?)?.toDouble() ?? 0.0,
        costPrice: (row['cost_price'] as num?)?.toDouble(),
        wholesalePrice: (row['wholesale_price'] as num?)?.toDouble(),
        mrp: (row['mrp'] as num?)?.toDouble(),
        barcode: row['barcode'] as String?,
        totalStock: (row['total_stock'] as num?)?.toInt() ?? 0,
        lowStockThreshold: (row['low_stock_threshold'] as num?)?.toInt() ?? 10,
        isLowStockWarning: (row['is_low_stock_warning'] as int?) == 1,
      );
    }).toList();
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

  // Soft delete product, its variants, and adjust stock status if necessary
  Future<void> deleteProduct(String productId) async {
    await _db.transaction((txn) async {
      // Deactivate product
      await txn.update(
        'products',
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [productId],
      );

      // Deactivate variants
      await txn.update(
        'product_variants',
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'product_id = ?',
        whereArgs: [productId],
      );
    });
  }

  // Get stock level by variant ID
  Future<StockLevel?> getStockLevelByVariantId(String variantId) async {
    final result = await _db.query(
      'stock_levels',
      where: 'product_variant_id = ?',
      whereArgs: [variantId],
    );

    if (result.isEmpty) return null;
    return StockLevel.fromJson(result.first);
  }

  // Private helper to create stock level
  Future<void> _createStockLevel(String variantId, int initialStock, int threshold) async {
    final id = 'stk_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();
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
      'created_at': now,
      'updated_at': now,
    });
    
    if (initialStock > 0) {
      await _db.insert('stock_movements', {
        'id': 'mov_${DateTime.now().microsecondsSinceEpoch}',
        'product_variant_id': variantId,
        'movement_type': 'IN',
        'quantity_change': initialStock,
        'quantity_before': 0,
        'quantity_after': initialStock,
        'reason': 'Initial Stock Configured',
        'created_at': now,
      });
    }
  }
}
