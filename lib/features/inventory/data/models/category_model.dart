// lib/features/inventory/data/models/category_model.dart
class Category {
  final String id;
  final String? parentId;
  final String name;
  final String? description;
  final String? iconName;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Category> subcategories;

  Category({
    required this.id,
    this.parentId,
    required this.name,
    this.description,
    this.iconName,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.subcategories = const [],
  });

  bool get isParentCategory => parentId == null;
  int get depth => parentId == null ? 0 : 1;

  factory Category.fromJson(Map<String, dynamic> json, [List<Category>? subcategories]) => Category(
    id: json['id'],
    parentId: json['parent_id'],
    name: json['name'],
    description: json['description'],
    iconName: json['icon_name'],
    displayOrder: json['display_order'] ?? 0, // Fixing typo in user roadmap if it exists, or matching DB
    isActive: json['is_active'] == 1,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    subcategories: subcategories ?? [],
  );

  // Correcting for the DB schema case
  factory Category.fromMap(Map<String, dynamic> json, [List<Category>? subcategories]) => Category(
    id: json['id'],
    parentId: json['parent_id'],
    name: json['name'],
    description: json['description'],
    iconName: json['icon_name'],
    displayOrder: json['display_order'] ?? 0,
    isActive: json['is_active'] == 1,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    subcategories: subcategories ?? [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'parent_id': parentId,
    'name': name,
    'description': description,
    'icon_name': iconName,
    'display_order': displayOrder,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
