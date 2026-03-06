// lib/features/inventory/data/models/product_variant_model.dart
class ProductVariant {
  final String id;
  final String productId;
  final String? variantName;
  final String sku;
  final String? barcode;
  final double costPrice;
  final double retailPrice;
  final double? wholesalePrice;
  final double? mrp;
  final String? variantImagePath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductVariant({
    required this.id,
    required this.productId,
    this.variantName,
    required this.sku,
    this.barcode,
    required this.costPrice,
    required this.retailPrice,
    this.wholesalePrice,
    this.mrp,
    this.variantImagePath,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  double getPrice({required String priceType}) {
    switch (priceType) {
      case 'cost':
        return costPrice;
      case 'retail':
        return retailPrice;
      case 'wholesale':
        return wholesalePrice ?? retailPrice;
      case 'mrp':
        return mrp ?? retailPrice;
      default:
        return retailPrice;
    }
  }

  double calculateProfit(double sellingPrice) {
    return sellingPrice - costPrice;
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    id: json['id'],
    productId: json['product_id'],
    variantName: json['variant_name'],
    sku: json['sku'],
    barcode: json['barcode'],
    costPrice: (json['cost_price'] as num).toDouble(),
    retailPrice: (json['retail_price'] as num).toDouble(),
    wholesalePrice: json['wholesale_price'] != null 
      ? (json['wholesale_price'] as num).toDouble() 
      : null,
    mrp: json['mrp'] != null ? (json['mrp'] as num).toDouble() : null,
    variantImagePath: json['variant_image_path'],
    isActive: json['is_active'] == 1,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
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
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
