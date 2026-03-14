// lib/features/inventory/data/repositories/carton_repository.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/carton_model.dart';
import '../models/stock_level_model.dart';

class CartonRepository {
  final AppDatabase database;

  CartonRepository({required this.database});

  Database get _db => database.database;

  // Receive new carton (Stock IN)
  Future<String> receiveCarton({
    required String productVariantId,
    required String cartonNumber,
    required int piecesPerCarton,
    required double costPerPiece,
    required int receivedQuantity,
    DateTime? expiryDate,
    String? supplierBatchId,
    String? supplierId,
    String? storageLocation,
    String? notes,
  }) async {
    final id = 'ctn_${DateTime.now().millisecondsSinceEpoch}';
    final cartonCost = piecesPerCarton * costPerPiece;

    await _db.transaction((txn) async {
      await txn.insert('cartons', {
        'id': id,
        'product_variant_id': productVariantId,
        'carton_number': cartonNumber,
        'pieces_per_carton': piecesPerCarton,
        'cost_per_piece': costPerPiece,
        'carton_cost': cartonCost,
        'received_quantity': receivedQuantity,
        'available_quantity': receivedQuantity,
        'is_opened': 0,
        'expiry_date': expiryDate?.toIso8601String(),
        'supplier_batch_id': supplierBatchId,
        'supplier_id': supplierId,
        'storage_location': storageLocation,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update stock level
      await _updateStockLevel(txn, productVariantId, receivedQuantity);

      // Record movement
      await _recordMovement(txn, productVariantId, id, 'IN', receivedQuantity, 'Purchase');
    });

    return id;
  }

  // Get cartons for a variant
  Future<List<Carton>> getCartonsByVariant(String variantId) async {
    final result = await _db.query(
      'cartons',
      where: 'product_variant_id = ?',
      whereArgs: [variantId],
      orderBy: 'created_at DESC',
    );
    return [for (var json in result) Carton.fromJson(json)];
  }

  // FIFO sell from cartons
  Future<void> sellFromCarton({
    required String variantId,
    required int quantitySold,
    required String transactionId,
  }) async {
    await _db.transaction((txn) async {
      // Find available cartons (opened first, then oldest)
      final cartonsResult = await txn.query(
        'cartons',
        where: 'product_variant_id = ? AND available_quantity > 0',
        whereArgs: [variantId],
        orderBy: 'is_opened DESC, created_at ASC',
      );

      int remainingToSell = quantitySold;
      for (var row in cartonsResult) {
        if (remainingToSell <= 0) break;
        
        final carton = Carton.fromJson(row);
        final sellFromThis = remainingToSell > carton.availableQuantity 
            ? carton.availableQuantity 
            : remainingToSell;

        await txn.update(
          'cartons',
          {
            'available_quantity': carton.availableQuantity - sellFromThis,
            'is_opened': 1,
            'opened_date': carton.isOpened ? carton.openedDate?.toIso8601String() : DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [carton.id],
        );

        // Record individual movement per carton if needed, or aggregate
        await _recordMovement(txn, variantId, carton.id, 'OUT', -sellFromThis, 'Sale', referenceId: transactionId);

        remainingToSell -= sellFromThis;
      }

      if (remainingToSell > 0) {
        throw Exception('Insufficient stock in cartons');
      }

      // Update aggregate stock level
      await _updateStockLevel(txn, variantId, -quantitySold);
    });
  }

  // Helper: Update aggregate stock level
  Future<void> _updateStockLevel(Transaction txn, String variantId, int increment) async {
    final result = await txn.query('stock_levels', where: 'product_variant_id = ?', whereArgs: [variantId]);
    if (result.isEmpty) return;

    final stock = StockLevel.fromJson(result.first);
    final newTotal = stock.totalPieces + increment;

    await txn.update(
      'stock_levels',
      {
        'total_pieces': newTotal,
        'available_pieces': newTotal - stock.reservedPieces,
        'is_low_stock_warning': (newTotal - stock.reservedPieces) <= stock.lowStockThreshold ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'product_variant_id = ?',
      whereArgs: [variantId],
    );
  }

  // Helper: Record movement
  Future<void> _recordMovement(
    Transaction txn,
    String variantId,
    String? cartonId,
    String type,
    int change,
    String reason, {
    String? referenceId,
  }) async {
    final stockResult = await txn.query('stock_levels', where: 'product_variant_id = ?', whereArgs: [variantId]);
    if (stockResult.isEmpty) return;
    
    final stock = StockLevel.fromJson(stockResult.first);

    await txn.insert('stock_movements', {
      'id': 'mov_${DateTime.now().millisecondsSinceEpoch}',
      'product_variant_id': variantId,
      'carton_id': cartonId,
      'movement_type': type,
      'quantity_change': change,
      'quantity_before': stock.totalPieces,
      'quantity_after': stock.totalPieces + change,
      'reason': reason,
      'reference_id': referenceId,
      'recorded_by': 'system',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
