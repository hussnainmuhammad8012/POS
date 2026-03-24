// lib/features/inventory/data/repositories/product_repository.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/product_model.dart';
import '../models/product_summary_model.dart';
import '../models/product_variant_model.dart';
import '../models/product_unit_model.dart';
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
    String? supplierId,
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
      'supplier_id': supplierId,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  /// Creates a product, its default variant, and initial stock level in a single transaction.
  Future<String> createProductWithDefaultVariant({
    required String categoryId,
    required String name,
    required String baseSku,
    String? description,
    String? unitType,
    String? supplierId,
    String? barcode,
    String? qrCode,
    required double costPrice,
    required double retailPrice,
    double? wholesalePrice,
    double? mrp,
    double taxRate = 0,
    int initialStock = 0,
    int lowStockThreshold = 10,
  }) async {
    return await _db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final productId = 'prod_${DateTime.now().millisecondsSinceEpoch}';
      
      // 1. Create Product
      await txn.insert('products', {
        'id': productId,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'base_sku': baseSku,
        'unit_type': unitType ?? 'Pieces',
        'supplier_id': supplierId,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });

      // 2. Create Default Variant
      final variantId = 'var_${DateTime.now().millisecondsSinceEpoch}';
      await txn.insert('product_variants', {
        'id': variantId,
        'product_id': productId,
        'variant_name': 'Default',
        'sku': '$baseSku-DEF',
        'barcode': barcode,
        'qr_code': qrCode,
        'cost_price': costPrice,
        'retail_price': retailPrice,
        'wholesale_price': wholesalePrice,
        'mrp': mrp,
        'tax_rate': taxRate,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });

      // 3. Create Stock Level
      final stockId = 'stk_${DateTime.now().millisecondsSinceEpoch}';
      await txn.insert('stock_levels', {
        'id': stockId,
        'product_variant_id': variantId,
        'total_pieces': initialStock,
        'total_cartons': 0,
        'reserved_pieces': 0,
        'available_pieces': initialStock,
        'low_stock_threshold': lowStockThreshold,
        'reorder_point': lowStockThreshold * 2,
        'is_low_stock_warning': initialStock <= lowStockThreshold ? 1 : 0,
        'created_at': now,
        'updated_at': now,
      });

      // 4. Record Initial Stock Movement
      if (initialStock > 0) {
        await txn.insert('stock_movements', {
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

      return productId;
    });
  }

  Future<String?> getPrimaryVariantId(String productId) async {
    final cleanId = productId.trim();
    // 1. Try exact match (active)
    final results = await _db.query(
      'product_variants',
      columns: ['id'],
      where: 'product_id = ? AND is_active = 1',
      whereArgs: [cleanId],
      limit: 1,
    );
    if (results.isNotEmpty) return results.first['id'] as String;

    // 2. Try case-insensitive match (active)
    final resultsCI = await _db.rawQuery(
      'SELECT id FROM product_variants WHERE product_id = ? COLLATE NOCASE AND is_active = 1 LIMIT 1',
      [cleanId],
    );
    if (resultsCI.isNotEmpty) return resultsCI.first['id'] as String;

    // 3. Fallback to ANY variant for this product
    final anyVariant = await _db.query(
      'product_variants',
      columns: ['id'],
      where: 'product_id = ?',
      whereArgs: [cleanId],
      limit: 1,
    );
    if (anyVariant.isNotEmpty) return anyVariant.first['id'] as String;

    // 4. AUTO-REPAIR: If product exists but has NO variant, create a default one
    final productCheck = await _db.query('products', where: 'id = ?', whereArgs: [cleanId]);
    if (productCheck.isNotEmpty) {
      print('REPAIR: Product $cleanId exists but has NO variants. Creating default...');
      final product = productCheck.first;
      final newVariantId = 'var_repair_${DateTime.now().millisecondsSinceEpoch}';
      
      await _db.transaction((txn) async {
        await txn.insert('product_variants', {
          'id': newVariantId,
          'product_id': cleanId,
          'variant_name': 'Default',
          'sku': '${product['base_sku']}-DEF-${DateTime.now().millisecond}',
          'cost_price': 0.0,
          'retail_price': 0.0,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        await txn.insert('stock_levels', {
          'id': 'stk_repair_${DateTime.now().millisecondsSinceEpoch}',
          'product_variant_id': newVariantId,
          'total_pieces': 0,
          'available_pieces': 0,
          'low_stock_threshold': 10,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      });
      return newVariantId;
    }

    return null;
  }

  Future<ProductVariant?> getVariantById(String id) async {
    final results = await _db.query('product_variants', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return ProductVariant.fromMap(results.first);
  }

  /// ==========================================
  /// MULTI-UOM SPECIFIC METHODS
  /// ==========================================

  /// Creates a product along with multiple UOMs (base unit + multipliers) and initial stock level.
  Future<String> createProductWithUoms({
    required String categoryId,
    required String name,
    required String baseSku,
    String? description,
    String? supplierId,
    required ProductUnit baseUnit,
    List<ProductUnit> multiplierUnits = const [],
    int initialBaseStock = 0,
    int lowStockThreshold = 10,
  }) async {
    return await _db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final productId = 'prod_${DateTime.now().millisecondsSinceEpoch}';
      
      // 1. Create Product
      await txn.insert('products', {
        'id': productId,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'base_sku': baseSku,
        'unit_type': baseUnit.unitName, // Fallback for backwards compatibility
        'supplier_id': supplierId,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });

      // 2. Insert Base Unit
      await txn.insert('product_units', {
        'id': baseUnit.id,
        'product_id': productId,
        'unit_name': baseUnit.unitName,
        'conversion_rate': baseUnit.conversionRate,
        'is_base_unit': 1,
        'barcode': baseUnit.barcode,
        'qr_code': baseUnit.qrCode,
        'cost_price': baseUnit.costPrice,
        'retail_price': baseUnit.retailPrice,
        'wholesale_price': baseUnit.wholesalePrice,
        'mrp': baseUnit.mrp,
        'tax_rate': baseUnit.taxRate,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });

      // 3. Insert Multiplier Units
      for (final unit in multiplierUnits) {
        await txn.insert('product_units', {
          'id': unit.id,
          'product_id': productId,
          'unit_name': unit.unitName,
          'conversion_rate': unit.conversionRate,
          'is_base_unit': 0,
          'barcode': unit.barcode,
          'qr_code': unit.qrCode,
          'cost_price': unit.costPrice,
          'retail_price': unit.retailPrice,
          'wholesale_price': unit.wholesalePrice,
          'mrp': unit.mrp,
          'tax_rate': unit.taxRate,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        });
      }

      // 4. Create Primary Variant for Stock tracking
      final variantId = 'v_${DateTime.now().millisecondsSinceEpoch}';
      await txn.insert('product_variants', {
        'id': variantId,
        'product_id': productId,
        'variant_name': 'Primary (${baseUnit.unitName})',
        'sku': baseSku,
        'cost_price': baseUnit.costPrice,
        'retail_price': baseUnit.retailPrice,
        'wholesale_price': baseUnit.wholesalePrice,
        'mrp': baseUnit.mrp,
        'tax_rate': baseUnit.taxRate,
        'barcode': baseUnit.barcode,
        'qr_code': baseUnit.qrCode,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });

      // 5. Create Stock Level
      final stockId = 'stk_${DateTime.now().millisecondsSinceEpoch}';
      await txn.insert('stock_levels', {
        'id': stockId,
        'product_variant_id': variantId, 
        'total_pieces': initialBaseStock,
        'total_cartons': 0,
        'reserved_pieces': 0,
        'available_pieces': initialBaseStock,
        'low_stock_threshold': lowStockThreshold,
        'reorder_point': lowStockThreshold * 2,
        'is_low_stock_warning': initialBaseStock <= lowStockThreshold ? 1 : 0,
        'created_at': now,
        'updated_at': now,
      });

      // 5. Record Initial Stock Movement
      if (initialBaseStock > 0) {
        await txn.insert('stock_movements', {
          'id': 'mov_${DateTime.now().microsecondsSinceEpoch}',
          'product_variant_id': variantId,
          'movement_type': 'IN',
          'quantity_change': initialBaseStock,
          'quantity_before': 0,
          'quantity_after': initialBaseStock,
          'reason': 'Initial Stock Configured via UOM',
          'created_at': now,
        });
      }

      return productId;
    });
  }

  Future<List<ProductUnit>> getUnitsByProductId(String productId) async {
    final results = await _db.query(
      'product_units',
      where: 'product_id = ? AND is_active = 1',
      whereArgs: [productId],
      orderBy: 'conversion_rate ASC',
    );
    return results.map((e) => ProductUnit.fromJson(e)).toList();
  }

  /// Looks up a product unit by any identifying code (barcode, QR code, or unit-specific SKU).
  Future<ProductUnit?> getUnitByBarcode(String barcode) async {
    final result = await _db.query(
      'product_units',
      where: '(barcode = ? OR qr_code = ?) AND is_active = 1',
      whereArgs: [barcode, barcode],
    );
    if (result.isEmpty) return null;
    return ProductUnit.fromJson(result.first);
  }

  Future<ProductUnit?> getBaseUnitByProductId(String productId) async {
    final result = await _db.query(
      'product_units',
      where: 'product_id = ? AND is_base_unit = 1 AND is_active = 1',
      whereArgs: [productId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ProductUnit.fromJson(result.first);
  }

  Future<void> updateProductWithUoms({
    required String productId,
    String? categoryId,
    String? name,
    String? baseSku,
    String? description,
    String? supplierId,
    required ProductUnit baseUnit,
    required List<ProductUnit> multiplierUnits,
    int? manualBaseStockAdjust,
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
      pUpdates['unit_type'] = baseUnit.unitName;
      if (supplierId != null) pUpdates['supplier_id'] = supplierId.isEmpty ? null : supplierId;

      await txn.update('products', pUpdates, where: 'id = ?', whereArgs: [productId]);

      // 2. Upsert Base Unit
      // We assume baseUnit.id already exists
      await txn.update('product_units', {
        'unit_name': baseUnit.unitName,
        'conversion_rate': baseUnit.conversionRate,
        'barcode': baseUnit.barcode,
        'qr_code': baseUnit.qrCode,
        'cost_price': baseUnit.costPrice,
        'retail_price': baseUnit.retailPrice,
        'wholesale_price': baseUnit.wholesalePrice,
        'mrp': baseUnit.mrp,
        'tax_rate': baseUnit.taxRate,
        'updated_at': now,
      }, where: 'id = ?', whereArgs: [baseUnit.id]);

      // 3. Sync Multiplier Units
      // For simplicity, we can deactivate existing multiplier units and insert/update the ones passed in
      // Deactivating all non-base units for this product
      await txn.update('product_units', {
        'is_active': 0,
        'updated_at': now,
      }, where: 'product_id = ? AND is_base_unit = 0', whereArgs: [productId]);

      for (final unit in multiplierUnits) {
        // Upsert by checking if it exists
        final exists = await txn.query('product_units', where: 'id = ?', whereArgs: [unit.id]);
        if (exists.isNotEmpty) {
          await txn.update('product_units', {
            'unit_name': unit.unitName,
            'conversion_rate': unit.conversionRate,
            'barcode': unit.barcode,
            'qr_code': unit.qrCode,
            'cost_price': unit.costPrice,
            'retail_price': unit.retailPrice,
            'wholesale_price': unit.wholesalePrice,
            'mrp': unit.mrp,
            'tax_rate': unit.taxRate,
            'is_active': 1,
            'updated_at': now,
          }, where: 'id = ?', whereArgs: [unit.id]);
        } else {
          await txn.insert('product_units', {
            'id': unit.id,
            'product_id': productId,
            'unit_name': unit.unitName,
            'conversion_rate': unit.conversionRate,
            'is_base_unit': 0,
            'barcode': unit.barcode,
            'qr_code': unit.qrCode,
            'cost_price': unit.costPrice,
            'retail_price': unit.retailPrice,
            'wholesale_price': unit.wholesalePrice,
            'mrp': unit.mrp,
            'tax_rate': unit.taxRate,
            'is_active': 1,
            'created_at': now,
            'updated_at': now,
          });
        }
      }

      // Mirror price updates to primary variant
      final variants = await txn.query('product_variants', where: 'product_id = ? AND is_active = 1', whereArgs: [productId]);
      String primaryVariantId = baseUnit.id;
      if (variants.isNotEmpty) {
        primaryVariantId = variants.first['id'] as String;
        await txn.update('product_variants', {
          'cost_price': baseUnit.costPrice,
          'retail_price': baseUnit.retailPrice,
          'wholesale_price': baseUnit.wholesalePrice,
          'mrp': baseUnit.mrp,
          'tax_rate': baseUnit.taxRate,
          'barcode': baseUnit.barcode,
          'qr_code': baseUnit.qrCode,
          'updated_at': now,
        }, where: 'id = ?', whereArgs: [primaryVariantId]);
      }

      // 4. Update Stock Level
      final sUpdates = <String, dynamic>{'updated_at': now};
      if (manualBaseStockAdjust != null) {
        sUpdates['total_pieces'] = manualBaseStockAdjust;
        sUpdates['available_pieces'] = manualBaseStockAdjust;
      }
      if (lowStockThreshold != null) {
        sUpdates['low_stock_threshold'] = lowStockThreshold;
      }

      if (sUpdates.length > 1) {
        final stocks = await txn.query('stock_levels', where: 'product_variant_id = ?', whereArgs: [primaryVariantId]);
        int prevStock = 0;
        
        if (stocks.isNotEmpty) {
           prevStock = (stocks.first['available_pieces'] as int?) ?? 0;
           final int currStock = manualBaseStockAdjust ?? prevStock;
           final int currThreshold = lowStockThreshold ?? (stocks.first['low_stock_threshold'] as int?) ?? 0;
           sUpdates['is_low_stock_warning'] = currStock <= currThreshold ? 1 : 0;
        }

        if (manualBaseStockAdjust != null && manualBaseStockAdjust != prevStock) {
           final int diff = manualBaseStockAdjust - prevStock;
           await txn.insert('stock_movements', {
             'id': 'mov_${DateTime.now().microsecondsSinceEpoch}',
             'product_variant_id': primaryVariantId,
             'movement_type': diff > 0 ? 'ADJUSTMENT' : 'OUT',
             'quantity_change': diff,
             'quantity_before': prevStock,
             'quantity_after': manualBaseStockAdjust,
             'reason': 'Manual Adjustment from Product UOM Form',
             'created_at': now,
           });
        }

        await txn.update('stock_levels', sUpdates, where: 'product_variant_id = ?', whereArgs: [primaryVariantId]);
      }
    });
  }

  /// ==========================================
  /// END MULTI-UOM METHODS
  /// ==========================================

  // Update product, its primary variant, and its stock level
  Future<void> updateProduct(String id, {
    String? categoryId,
    String? name,
    String? baseSku,
    String? description,
    String? mainImagePath,
    String? unitType,
    String? supplierId,
    double? costPrice,
    double? retailPrice,
    double? wholesalePrice,
    double? mrp,
    String? barcode,
    String? qrCode,
    double? taxRate,
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
      // Allow clearing supplier ID explicitly by checking if it's passed or handle it separately if needed
      // For now, if supplierId is passed, update it. If we need to clear it, we might need a different approach.
      if (supplierId != null) pUpdates['supplier_id'] = supplierId.isEmpty ? null : supplierId;

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
        if (taxRate != null) vUpdates['tax_rate'] = taxRate;
        if (barcode != null) vUpdates['barcode'] = barcode;
        if (qrCode != null) vUpdates['qr_code'] = qrCode;

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
    String? qrCode,
    required double costPrice,
    required double retailPrice,
    double? wholesalePrice,
    double? mrp,
    double taxRate = 0,
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
      'qr_code': qrCode,
      'cost_price': costPrice,
      'retail_price': retailPrice,
      'wholesale_price': wholesalePrice,
      'mrp': mrp,
      'variant_image_path': variantImagePath,
      'tax_rate': taxRate,
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
        COALESCE(
          (SELECT MIN(retail_price) FROM product_variants WHERE product_id = p.id AND is_active = 1),
          (SELECT MIN(retail_price) FROM product_units WHERE product_id = p.id AND is_active = 1),
          0
        ) as min_price,
        COALESCE(
          (SELECT MAX(retail_price) FROM product_variants WHERE product_id = p.id AND is_active = 1),
          (SELECT MAX(retail_price) FROM product_units WHERE product_id = p.id AND is_active = 1),
          0
        ) as max_price,
        (SELECT MIN(cost_price) FROM product_variants WHERE product_id = p.id AND is_active = 1) as cost_price,
        (SELECT MIN(wholesale_price) FROM product_variants WHERE product_id = p.id AND is_active = 1) as wholesale_price,
        (SELECT MIN(mrp) FROM product_variants WHERE product_id = p.id AND is_active = 1) as mrp,
        COALESCE(
          (SELECT barcode FROM product_variants WHERE product_id = p.id AND is_active = 1 LIMIT 1),
          (SELECT barcode FROM product_units WHERE product_id = p.id AND is_active = 1 LIMIT 1)
        ) as barcode,
        COALESCE(
          (SELECT qr_code FROM product_variants WHERE product_id = p.id AND is_active = 1 LIMIT 1),
          (SELECT qr_code FROM product_units WHERE product_id = p.id AND is_active = 1 LIMIT 1)
        ) as qr_code,
        COALESCE(
          (SELECT SUM(available_pieces) FROM stock_levels WHERE product_variant_id IN (SELECT id FROM product_variants WHERE product_id = p.id AND is_active = 1)),
          (SELECT SUM(available_pieces) FROM stock_levels WHERE product_variant_id IN (SELECT id FROM product_units WHERE product_id = p.id AND is_active = 1)),
          0
        ) as total_stock,
        COALESCE(
          (SELECT MAX(low_stock_threshold) FROM stock_levels WHERE product_variant_id IN (SELECT id FROM product_variants WHERE product_id = p.id AND is_active = 1)),
          (SELECT MAX(low_stock_threshold) FROM stock_levels WHERE product_variant_id IN (SELECT id FROM product_units WHERE product_id = p.id AND is_active = 1)),
          10
        ) as low_stock_threshold,
        COALESCE(
          (SELECT MAX(is_low_stock_warning) FROM stock_levels WHERE product_variant_id IN (SELECT id FROM product_variants WHERE product_id = p.id AND is_active = 1)),
          (SELECT MAX(is_low_stock_warning) FROM stock_levels WHERE product_variant_id IN (SELECT id FROM product_units WHERE product_id = p.id AND is_active = 1)),
          0
        ) as is_low_stock_warning,
        (SELECT id FROM product_variants WHERE product_id = p.id AND is_active = 1 LIMIT 1) as primary_variant_id
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
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
    
    // Fetch all units for these products in one go to optimize
    final productIds = result.map((r) => r['id'] as String).toList();
    Map<String, List<ProductUnit>> unitMap = {};
    if (productIds.isNotEmpty) {
      final unitResults = await _db.query(
        'product_units',
        where: 'product_id IN (${productIds.map((_) => '?').join(',')}) AND is_active = 1',
        whereArgs: productIds,
      );
      for (var unitJson in unitResults) {
        final unit = ProductUnit.fromJson(unitJson);
        unitMap.putIfAbsent(unit.productId, () => []).add(unit);
      }
    }

    return result.map((row) {
      final productId = row['id'] as String;
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
        qrCode: row['qr_code'] as String?,
        totalStock: (row['total_stock'] as num?)?.toInt() ?? 0,
        units: unitMap[productId] ?? [],
        primaryVariantId: row['primary_variant_id'] as String?,
        lowStockThreshold: (row['low_stock_threshold'] as num?)?.toInt() ?? 10,
        isLowStockWarning: (row['is_low_stock_warning'] as int?) == 1,
      );
    }).toList();
  }

  // Get product with all variants
  Future<Map<String, dynamic>?> getProductWithVariants(String productId) async {
    final cleanId = productId.trim();
    final productResult = await _db.rawQuery(
      'SELECT * FROM products WHERE id = ? COLLATE NOCASE',
      [cleanId],
    );

    if (productResult.isEmpty) return null;

    var variants = await _db.rawQuery(
      'SELECT * FROM product_variants WHERE product_id = ? COLLATE NOCASE',
      [cleanId],
    );

    // AUTO-REPAIR: If zero variants, create a default one and re-query
    if (variants.isEmpty) {
      await getPrimaryVariantId(cleanId); // Triggers repair
      variants = await _db.rawQuery(
        'SELECT * FROM product_variants WHERE product_id = ? COLLATE NOCASE',
        [cleanId],
      );
    }

    return {
      'product': Product.fromJson(productResult.first),
      'variants': [for (var v in variants) ProductVariant.fromJson(v)],
    };
  }

  /// Looks up a product variant by any identifying code (barcode, QR code, or SKU).
  Future<ProductVariant?> getVariantByBarcode(String barcode) async {
    final result = await _db.query(
      'product_variants',
      where: '(barcode = ? OR qr_code = ? OR sku = ?) AND is_active = 1',
      whereArgs: [barcode, barcode, barcode],
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
    final rows = await _db.query(
      'stock_levels',
      where: 'product_variant_id = ?',
      whereArgs: [variantId],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    
    // Available to sell = actual available - currently reserved in mobile carts
    final int reserved = (row['reserved_pieces'] as num?)?.toInt() ?? 0;
    final int available = (row['available_pieces'] as num).toInt();

    return StockLevel(
      id: row['id'] as String,
      productVariantId: row['product_variant_id'] as String,
      availablePieces: (available - reserved).clamp(0, available),
      totalPieces: (row['total_pieces'] as num).toInt(),
      totalCartons: (row['total_cartons'] as num?)?.toInt() ?? 0,
      reservedPieces: reserved,
      lowStockThreshold: (row['low_stock_threshold'] as num).toInt(),
      reorderPoint: (row['reorder_point'] as num?)?.toInt() ?? 10,
      isLowStockWarning: row['is_low_stock_warning'] == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<void> reserveStock({
    required String variantId,
    required int quantity,
    required String deviceId,
  }) async {
    await _db.transaction((txn) async {
      // 1. Update stock_levels
      await txn.rawUpdate(
        'UPDATE stock_levels SET reserved_pieces = reserved_pieces + ? WHERE product_variant_id = ?',
        [quantity, variantId],
      );

      // 2. Track reservation
      await txn.insert('mobile_cart_reservations', {
        'id': 'res_${DateTime.now().microsecondsSinceEpoch}',
        'device_id': deviceId,
        'product_variant_id': variantId,
        'quantity': quantity,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> releaseStock({
    required String deviceId,
    String? variantId,
    int? quantity,
  }) async {
    await _db.transaction((txn) async {
      if (variantId != null && quantity != null) {
        // Release specific amount
        await txn.rawUpdate(
          'UPDATE stock_levels SET reserved_pieces = reserved_pieces - ? WHERE product_variant_id = ?',
          [quantity, variantId],
        );
        // Find and remove matching reservation record (oldest first)
        final res = await txn.query(
          'mobile_cart_reservations',
          where: 'device_id = ? AND product_variant_id = ?',
          whereArgs: [deviceId, variantId],
          limit: 1,
        );
        if (res.isNotEmpty) {
           await txn.delete('mobile_cart_reservations', where: 'id = ?', whereArgs: [res.first['id']]);
        }
      } else {
        // Release all for device (Void Cart)
        final reservations = await txn.query(
          'mobile_cart_reservations',
          where: 'device_id = ?',
          whereArgs: [deviceId],
        );
        for (final res in reservations) {
          final vId = res['product_variant_id'] as String;
          final qty = res['quantity'] as int;
          await txn.rawUpdate(
            'UPDATE stock_levels SET reserved_pieces = reserved_pieces - ? WHERE product_variant_id = ?',
            [qty, vId],
          );
        }
        await txn.delete('mobile_cart_reservations', where: 'device_id = ?', whereArgs: [deviceId]);
      }
    });
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

  // Update stock for a product's primary variant
  Future<void> updateStock({
    required String productId,
    required int quantityChange,
    required String reason,
  }) async {
    await _db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      
      // 1. Find the primary variant
      final variants = await txn.query(
        'product_variants',
        where: 'product_id = ? AND is_active = 1',
        whereArgs: [productId],
        limit: 1,
      );
      
      if (variants.isEmpty) return;
      final variantId = variants.first['id'] as String;
      
      // 2. Get current stock
      final stocks = await txn.query(
        'stock_levels',
        where: 'product_variant_id = ?',
        whereArgs: [variantId],
      );
      
      if (stocks.isEmpty) return;
      final int prevStock = (stocks.first['available_pieces'] as int?) ?? 0;
      final int newStock = prevStock + quantityChange;
      final int threshold = (stocks.first['low_stock_threshold'] as int?) ?? 10;
      
      // 3. Update stock_levels
      await txn.update(
        'stock_levels',
        {
          'available_pieces': newStock,
          'total_pieces': newStock, 
          'is_low_stock_warning': newStock <= threshold ? 1 : 0,
          'updated_at': now,
        },
        where: 'product_variant_id = ?',
        whereArgs: [variantId],
      );
      
      // 4. Record movement
      await txn.insert('stock_movements', {
        'id': 'mov_${DateTime.now().microsecondsSinceEpoch}',
        'product_variant_id': variantId,
        'movement_type': quantityChange > 0 ? 'ADJUSTMENT' : 'OUT',
        'quantity_change': quantityChange,
        'quantity_before': prevStock,
        'quantity_after': newStock,
        'reason': reason,
        'created_at': now,
      });
    });
  }

  /// Formats a total number of pieces into a human-readable string based on available units.
  /// Example: 10 pieces with a "Pet" unit (6 pieces) -> "1 Pet 4 Pieces"
  Future<String> formatStockPieces(String productId, int totalPieces) async {
    final units = await getUnitsByProductId(productId);
    if (units.isEmpty) return totalPieces.toString();

    // Sort units by conversion rate descending (largest first)
    final sortedUnits = List<ProductUnit>.from(units)
      ..sort((a, b) => b.conversionRate.compareTo(a.conversionRate));

    List<String> parts = [];
    int remaining = totalPieces;

    for (final unit in sortedUnits) {
      if (unit.conversionRate > 1 && remaining >= unit.conversionRate) {
        int count = remaining ~/ unit.conversionRate;
        remaining %= unit.conversionRate;
        parts.add('$count ${unit.unitName}');
      } else if (unit.isBaseUnit && remaining > 0) {
        parts.add('$remaining ${unit.unitName}');
        remaining = 0;
      }
    }

    if (parts.isEmpty && totalPieces > 0) {
      // Fallback if no base unit found but we have pieces
      return '$totalPieces Pieces';
    }

    return parts.isEmpty ? '0' : parts.join(' ');
  }
}
