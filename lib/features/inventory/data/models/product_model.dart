// lib/features/inventory/data/models/product_model.dart
class Product {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final String baseSku;
  final String? mainImagePath;
  final String unitType; // 'pieces', 'kg', 'liter', etc.
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.baseSku,
    this.mainImagePath,
    required this.unitType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    categoryId: json['category_id'],
    name: json['name'],
    description: json['description'],
    baseSku: json['base_sku'],
    mainImagePath: json['main_image_path'],
    unitType: json['unit_type'],
    isActive: json['is_active'] == 1,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'base_sku': baseSku,
    'main_image_path': mainImagePath,
    'unit_type': unitType,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
