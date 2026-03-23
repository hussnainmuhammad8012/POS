// lib/features/inventory/data/models/product_unit_model.dart
class ProductUnit {
  final String id;
  final String productId;
  final String unitName; // e.g., 'Piece', 'Box', 'Carton'
  final int conversionRate; // Multiplier vs base unit. Piece = 1, Box = 12
  final bool isBaseUnit;
  final String? barcode;
  final String? qrCode;
  final double costPrice;
  final double retailPrice;
  final double? wholesalePrice;
  final double? mrp;
  final double taxRate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductUnit({
    required this.id,
    required this.productId,
    required this.unitName,
    required this.conversionRate,
    required this.isBaseUnit,
    this.barcode,
    this.qrCode,
    required this.costPrice,
    required this.retailPrice,
    this.wholesalePrice,
    this.mrp,
    this.taxRate = 0.0,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductUnit.fromJson(Map<String, dynamic> json) => ProductUnit(
        id: json['id'],
        productId: json['product_id'],
        unitName: json['unit_name'],
        conversionRate: (json['conversion_rate'] as num?)?.toInt() ?? 1,
        isBaseUnit: json['is_base_unit'] == 1,
        barcode: json['barcode'],
        qrCode: json['qr_code'],
        costPrice: (json['cost_price'] as num).toDouble(),
        retailPrice: (json['retail_price'] as num).toDouble(),
        wholesalePrice: json['wholesale_price'] != null
            ? (json['wholesale_price'] as num).toDouble()
            : null,
        mrp: json['mrp'] != null ? (json['mrp'] as num).toDouble() : null,
        taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
        isActive: json['is_active'] == 1,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'unit_name': unitName,
        'conversion_rate': conversionRate,
        'is_base_unit': isBaseUnit ? 1 : 0,
        'barcode': barcode,
        'qr_code': qrCode,
        'cost_price': costPrice,
        'retail_price': retailPrice,
        'wholesale_price': wholesalePrice,
        'mrp': mrp,
        'tax_rate': taxRate,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
