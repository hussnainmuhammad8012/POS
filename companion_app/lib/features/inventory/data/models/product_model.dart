class Product {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final String baseSku;
  final String? mainImagePath;
  final String unitType;
  final String? supplierId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int currentStock;
  final double price;
  
  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.baseSku,
    this.mainImagePath,
    required this.unitType,
    this.supplierId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.currentStock = 0,
    this.price = 0.0,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    categoryId: json['category_id'],
    name: json['name'],
    description: json['description'],
    baseSku: json['base_sku'],
    mainImagePath: json['main_image_path'],
    unitType: json['unit_type'],
    supplierId: json['supplier_id'],
    isActive: json['is_active'] == 1 || json['is_active'] == true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    currentStock: (json['current_stock'] as num?)?.toInt() ?? 0,
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'base_sku': baseSku,
    'main_image_path': mainImagePath,
    'unit_type': unitType,
    'supplier_id': supplierId,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'current_stock': currentStock,
    'price': price,
  };
}
