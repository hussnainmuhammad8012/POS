import 'product_model.dart';
import 'product_unit_model.dart';

class ProductSummary {
  final Product product;
  final String? categoryName;
  final double minPrice;
  final double maxPrice;
  final double? costPrice;
  final double? wholesalePrice;
  final double? mrp;
  final String? barcode;
  final String? qrCode;
  final int totalStock;
  final List<ProductUnit> units;
  final int lowStockThreshold;
  final bool isLowStockWarning;

  ProductSummary({
    required this.product,
    this.categoryName,
    required this.minPrice,
    required this.maxPrice,
    this.costPrice,
    this.wholesalePrice,
    this.mrp,
    this.barcode,
    this.qrCode,
    required this.totalStock,
    this.units = const [],
    required this.lowStockThreshold,
    required this.isLowStockWarning,
  });

  String get priceRange {
    if (minPrice == maxPrice) {
      return '\$${minPrice.toStringAsFixed(2)}';
    }
    return '\$${minPrice.toStringAsFixed(2)} - \$${maxPrice.toStringAsFixed(2)}';
  }
}
