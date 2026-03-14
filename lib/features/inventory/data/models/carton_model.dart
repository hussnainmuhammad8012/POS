// lib/features/inventory/data/models/carton_model.dart
class Carton {
  final String id;
  final String productVariantId;
  final String cartonNumber;
  final int piecesPerCarton;
  final double costPerPiece;
  final double cartonCost;
  final int receivedQuantity;
  final int availableQuantity;
  final DateTime? openedDate;
  final bool isOpened;
  final DateTime? expiryDate;
  final String? supplierBatchId;
  final String? supplierId;
  final String? storageLocation;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Carton({
    required this.id,
    required this.productVariantId,
    required this.cartonNumber,
    required this.piecesPerCarton,
    required this.costPerPiece,
    required this.cartonCost,
    required this.receivedQuantity,
    required this.availableQuantity,
    this.openedDate,
    required this.isOpened,
    this.expiryDate,
    this.supplierBatchId,
    this.supplierId,
    this.storageLocation,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  int get soldQuantity => receivedQuantity - availableQuantity;
  double get costPerUnit => cartonCost / piecesPerCarton;
  bool get isNearEmpty => availableQuantity <= (piecesPerCarton ~/ 4);
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());

  factory Carton.fromJson(Map<String, dynamic> json) => Carton(
    id: json['id'],
    productVariantId: json['product_variant_id'],
    cartonNumber: json['carton_number'],
    piecesPerCarton: json['pieces_per_carton'],
    costPerPiece: (json['cost_per_piece'] as num).toDouble(),
    cartonCost: (json['carton_cost'] as num).toDouble(),
    receivedQuantity: json['received_quantity'],
    availableQuantity: json['available_quantity'],
    openedDate: json['opened_date'] != null ? DateTime.parse(json['opened_date']) : null,
    isOpened: json['is_opened'] == 1,
    expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
    supplierBatchId: json['supplier_batch_id'],
    supplierId: json['supplier_id'],
    storageLocation: json['storage_location'],
    notes: json['notes'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_variant_id': productVariantId,
    'carton_number': cartonNumber,
    'pieces_per_carton': piecesPerCarton,
    'cost_per_piece': costPerPiece,
    'carton_cost': cartonCost,
    'received_quantity': receivedQuantity,
    'available_quantity': availableQuantity,
    'opened_date': openedDate?.toIso8601String(),
    'is_opened': isOpened ? 1 : 0,
    'expiry_date': expiryDate?.toIso8601String(),
    'supplier_batch_id': supplierBatchId,
    'supplier_id': supplierId,
    'storage_location': storageLocation,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
