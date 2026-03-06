// lib/features/inventory/data/models/stock_level_model.dart
class StockLevel {
  final String id;
  final String productVariantId;
  final int totalPieces;
  final int totalCartons;
  final int reservedPieces;
  final int availablePieces;
  final int lowStockThreshold;
  final int reorderPoint;
  final bool isLowStockWarning;
  final DateTime? lastCountedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  StockLevel({
    required this.id,
    required this.productVariantId,
    required this.totalPieces,
    required this.totalCartons,
    required this.reservedPieces,
    required this.availablePieces,
    required this.lowStockThreshold,
    required this.reorderPoint,
    required this.isLowStockWarning,
    this.lastCountedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get needsReorder => availablePieces <= reorderPoint;
  bool get isCriticallyLow => availablePieces <= lowStockThreshold;
  double get stockPercentage => totalPieces > 0 ? (availablePieces / totalPieces) * 100 : 0;

  factory StockLevel.fromJson(Map<String, dynamic> json) => StockLevel(
    id: json['id'],
    productVariantId: json['product_variant_id'],
    totalPieces: json['total_pieces'] ?? 0,
    totalCartons: json['total_cartons'] ?? 0,
    reservedPieces: json['reserved_pieces'] ?? 0,
    availablePieces: json['available_pieces'] ?? 0,
    lowStockThreshold: json['low_stock_threshold'] ?? 10,
    reorderPoint: json['reorder_point'] ?? 20,
    isLowStockWarning: (json['is_low_stock_warning'] == 1),
    lastCountedAt: json['last_counted_at'] != null ? DateTime.parse(json['last_counted_at']) : null,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_variant_id': productVariantId,
    'total_pieces': totalPieces,
    'total_cartons': totalCartons,
    'reserved_pieces': reservedPieces,
    'available_pieces': availablePieces,
    'low_stock_threshold': lowStockThreshold,
    'reorder_point': reorderPoint,
    'is_low_stock_warning': isLowStockWarning ? 1 : 0,
    'last_counted_at': lastCountedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
