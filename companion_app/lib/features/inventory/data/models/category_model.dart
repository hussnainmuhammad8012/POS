class Category {
  final String id;
  final String? parentId;
  final String name;
  final String? description;
  final String? iconName;
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
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.subcategories = const [],
  });

  Category copyWith({List<Category>? subcategories}) => Category(
    id: id,
    parentId: parentId,
    name: name,
    description: description,
    iconName: iconName,
    isActive: isActive,
    createdAt: createdAt,
    updatedAt: updatedAt,
    subcategories: subcategories ?? this.subcategories,
  );

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    parentId: json['parent_id'],
    name: json['name'],
    description: json['description'],
    iconName: json['icon_name'],
    isActive: json['is_active'] == 1 || json['is_active'] == true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    subcategories: (json['subcategories'] as List?)?.map((j) => Category.fromJson(j)).toList() ?? const [],
  );
}

