// companion_app/lib/features/inventory/data/models/stock_movement_model.dart

class CompanionStockMovement {
  final String id;
  final String? productName;
  final String? productId;
  final String? categoryName;
  final String movementType; // 'IN', 'OUT', 'ADJUSTMENT', 'RETURN', 'DAMAGE'
  final int quantityChange;
  final int quantityBefore;
  final int quantityAfter;
  final String reason;
  final String? notes;
  final String? unitId;
  final String? unitName;
  final String? referenceId;
  final DateTime createdAt;

  CompanionStockMovement({
    required this.id,
    this.productName,
    this.productId,
    this.categoryName,
    required this.movementType,
    required this.quantityChange,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.reason,
    this.notes,
    this.unitId,
    this.unitName,
    this.referenceId,
    required this.createdAt,
  });

  bool get isReturn => movementType == 'IN' &&
      (reason.toLowerCase().contains('return') ||
          reason.toLowerCase().contains('customer return'));

  factory CompanionStockMovement.fromJson(Map<String, dynamic> json) =>
      CompanionStockMovement(
        id: json['id'] ?? '',
        productName: json['product_name'],
        productId: json['product_id'],
        categoryName: json['category_name'],
        movementType: json['movement_type'] ?? 'ADJUSTMENT',
        quantityChange: (json['quantity_change'] as num?)?.toInt() ?? 0,
        quantityBefore: (json['quantity_before'] as num?)?.toInt() ?? 0,
        quantityAfter: (json['quantity_after'] as num?)?.toInt() ?? 0,
        reason: json['reason'] ?? '',
        notes: json['notes'],
        unitId: json['unit_id'],
        unitName: json['unit_name'],
        referenceId: json['reference_id'],
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
}
