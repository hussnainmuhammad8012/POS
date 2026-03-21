// lib/features/inventory/data/models/stock_movement_model.dart
class StockMovement {
  final String id;
  final String productVariantId;
  final String? cartonId;
  final String movementType; // 'IN', 'OUT', 'ADJUSTMENT', 'RETURN', 'DAMAGE'
  final int quantityChange;
  final int quantityBefore;
  final int quantityAfter;
  final String reason; // 'Purchase', 'Sale', 'Customer Return', 'Expiry', 'Damage', 'Inventory Correction'
  final String? referenceId; // Links to transaction_id, purchase_order_id, etc.
  final String? notes;
  final String? recordedBy;
  final String? productName;
  final String? categoryName;
  final String? productId;     // Added
  final String? categoryId;    // Added
  final String? unitId;        // Added
  final String? unitName;      // Added
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.productVariantId,
    this.cartonId,
    required this.movementType,
    required this.quantityChange,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.reason,
    this.referenceId,
    this.notes,
    this.recordedBy,
    this.productName,
    this.categoryName,
    this.productId,
    this.categoryId,
    this.unitId,
    this.unitName,
    required this.createdAt,
  });

  bool get isInbound => movementType == 'IN';
  bool get isOutbound => movementType == 'OUT';
  
  // Icon and Badge Color mapping could be handled in UI or here as helper getters
  
  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
    id: json['id'],
    productVariantId: json['product_variant_id'],
    cartonId: json['carton_id'],
    movementType: json['movement_type'],
    quantityChange: json['quantity_change'],
    quantityBefore: json['quantity_before'],
    quantityAfter: json['quantity_after'],
    reason: json['reason'],
    referenceId: json['reference_id'],
    notes: json['notes'],
    recordedBy: json['recorded_by'],
    productName: json['product_name'],
    categoryName: json['category_name'],
    productId: json['product_id'],
    categoryId: json['category_id'],
    unitId: json['unit_id'],
    unitName: json['unit_name'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_variant_id': productVariantId,
    'carton_id': cartonId,
    'movement_type': movementType,
    'quantity_change': quantityChange,
    'quantity_before': quantityBefore,
    'quantity_after': quantityAfter,
    'reason': reason,
    'reference_id': referenceId,
    'notes': notes,
    'recorded_by': recordedBy,
    'unit_id': unitId,
    'unit_name': unitName,
    'created_at': createdAt.toIso8601String(),
  };
}
