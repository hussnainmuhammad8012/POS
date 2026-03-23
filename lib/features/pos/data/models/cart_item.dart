import '../../../inventory/data/models/product_unit_model.dart';

class CartItem {
  final String id;
  final String variantId;   // For UOM items: "productId__unitId". For classic: variantId.
  final String productName;
  final String productSku;
  final String variantName;
  final double unitPrice;
  int quantity;
  final String? cartonId;
  final double profitMargin;
  final int availableStock;
  final double unitDiscount; // Discount per unit
  final double unitDiscountPercent; // Store entered percentage
  final double taxRate;   // Tax rate per unit
  final double taxAmount; // Total tax for this item
  
  // UOM-specific fields (null for classic items)
  final String? unitId;
  final String? unitName;
  final int conversionRate;   // 1 for classic/base items
  final String? baseVariantId; // The actual variant/unit ID for stock deduction
  final List<ProductUnit> productUnits;

  CartItem({
    required this.id,
    required this.variantId,
    required this.productName,
    required this.productSku,
    required this.variantName,
    required this.unitPrice,
    required this.quantity,
    this.cartonId,
    required this.profitMargin,
    required this.availableStock,
    this.unitDiscount = 0.0,
    this.unitDiscountPercent = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.unitId,
    this.unitName,
    this.conversionRate = 1,
    this.baseVariantId,
    this.productUnits = const [],
  });

  bool get isUomItem => unitId != null;

  double get subtotal => ((unitPrice - unitDiscount) * quantity);
  
  double get totalDiscount => unitDiscount * quantity;
  
  /// The total number of base units this cart item will consume from stock.
  int get baseUnitEquivalent => quantity * conversionRate;

  CartItem copyWith({
    String? variantId,
    String? unitId,
    String? unitName,
    int? conversionRate,
    double? unitPrice,
    int? quantity,
    String? variantName,
    double? profitMargin,
    double? unitDiscount,
    double? unitDiscountPercent,
    double? taxRate,
    double? taxAmount,
  }) {
    return CartItem(
      id: id,
      variantId: variantId ?? this.variantId,
      productName: productName,
      productSku: productSku,
      variantName: variantName ?? this.variantName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      cartonId: cartonId,
      profitMargin: profitMargin ?? this.profitMargin,
      availableStock: availableStock,
      unitDiscount: unitDiscount ?? this.unitDiscount,
      unitDiscountPercent: unitDiscountPercent ?? this.unitDiscountPercent,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      conversionRate: conversionRate ?? this.conversionRate,
      baseVariantId: baseVariantId,
      productUnits: productUnits,
    );
  }
}
