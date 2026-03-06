// lib/features/inventory/data/repositories/stock_movement_repository.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/stock_movement_model.dart';
import '../models/stock_level_model.dart';

class StockMovementRepository {
  final AppDatabase database;

  StockMovementRepository({required this.database});

  Database get _db => database.database;

  // Get all movements with filters
  Future<List<StockMovement>> getAllMovements({
    String? productVariantId,
    String? movementType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String query = '''
      SELECT m.*, p.name as product_name, c.name as category_name
      FROM stock_movements m
      JOIN product_variants v ON m.product_variant_id = v.id
      JOIN products p ON v.product_id = p.id
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE 1=1
    ''';
    List<dynamic> args = [];

    if (productVariantId != null) {
      query += ' AND m.product_variant_id = ?';
      args.add(productVariantId);
    }

    if (movementType != null && movementType != 'ALL') {
      query += ' AND m.movement_type = ?';
      args.add(movementType);
    }

    if (startDate != null) {
      query += ' AND m.created_at >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      query += ' AND m.created_at <= ?';
      args.add(endDate.toIso8601String());
    }

    query += ' ORDER BY m.created_at DESC';

    final result = await _db.rawQuery(query, args);
    return [for (var json in result) StockMovement.fromJson(json)];
  }

  // Record manual adjustment
  Future<void> recordAdjustment({
    required String productVariantId,
    required int quantityAdjustment,
    required String reason,
    String? notes,
  }) async {
    await _db.transaction((txn) async {
      final stockResult = await txn.query(
        'stock_levels',
        where: 'product_variant_id = ?',
        whereArgs: [productVariantId],
      );

      if (stockResult.isEmpty) throw Exception('Stock level not found');

      final stock = StockLevel.fromJson(stockResult.first);
      final newTotal = stock.totalPieces + quantityAdjustment;

      // Update Stock Level
      await txn.update(
        'stock_levels',
        {
          'total_pieces': newTotal,
          'available_pieces': newTotal - stock.reservedPieces,
          'is_low_stock_warning': (newTotal - stock.reservedPieces) <= stock.lowStockThreshold ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'product_variant_id = ?',
        whereArgs: [productVariantId],
      );

      // Record Movement
      await txn.insert('stock_movements', {
        'id': 'mov_${DateTime.now().millisecondsSinceEpoch}',
        'product_variant_id': productVariantId,
        'movement_type': 'ADJUSTMENT',
        'quantity_change': quantityAdjustment,
        'quantity_before': stock.totalPieces,
        'quantity_after': newTotal,
        'reason': reason,
        'notes': notes,
        'recorded_by': 'system',
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  // Record Customer Return
  Future<void> recordReturn({
    required String productVariantId,
    required int quantityReturned,
    required String transactionId,
    String? notes,
  }) async {
    await recordAdjustment(
      productVariantId: productVariantId,
      quantityAdjustment: quantityReturned,
      reason: 'Customer Return (Tx: $transactionId)',
      notes: notes,
    );
  }
}
