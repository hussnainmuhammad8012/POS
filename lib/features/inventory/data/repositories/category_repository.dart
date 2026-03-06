// lib/features/inventory/data/repositories/category_repository.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final AppDatabase database;

  CategoryRepository({required this.database});

  Database get _db => database.database;

  // Get all parent categories with subcategories
  Future<List<Category>> getAllCategoriesHierarchy() async {
    final parentCategories = await _db.query(
      'categories',
      where: 'parent_id IS NULL AND is_active = 1',
      orderBy: 'display_order ASC',
    );

    List<Category> result = [];
    for (var parentJson in parentCategories) {
      final subcategories = await _db.query(
        'categories',
        where: 'parent_id = ? AND is_active = 1',
        whereArgs: [parentJson['id']],
        orderBy: 'display_order ASC',
      );

      result.add(Category.fromMap(
        parentJson,
        [for (var subJson in subcategories) Category.fromMap(subJson)],
      ));
    }
    return result;
  }

  // Get flat list of all categories
  Future<List<Category>> getAllCategories({bool includeInactive = false}) async {
    final query = includeInactive 
      ? 'SELECT * FROM categories ORDER BY parent_id, display_order ASC'
      : 'SELECT * FROM categories WHERE is_active = 1 ORDER BY parent_id, display_order ASC';
    
    final result = await _db.rawQuery(query);
    return [for (var json in result) Category.fromMap(json)];
  }

  // Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    final result = await _db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );

    if (result.isEmpty) return null;

    final subcategories = await _db.query(
      'categories',
      where: 'parent_id = ? AND is_active = 1',
      whereArgs: [categoryId],
    );

    return Category.fromMap(
      result.first,
      [for (var subJson in subcategories) Category.fromMap(subJson)],
    );
  }

  // Create category
  Future<String> createCategory({
    required String name,
    String? parentId,
    String? description,
    String? iconName,
    int displayOrder = 0,
  }) async {
    final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    await _db.insert('categories', {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'display_order': displayOrder,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  // Update category
  Future<void> updateCategory({
    required String categoryId,
    String? name,
    String? description,
    String? iconName,
    int? displayOrder,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (iconName != null) updates['icon_name'] = iconName;
    if (displayOrder != null) updates['display_order'] = displayOrder;
    if (isActive != null) updates['is_active'] = isActive ? 1 : 0;

    await _db.update(
      'categories',
      updates,
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  // Delete category (soft delete)
  Future<void> deleteCategory(String categoryId) async {
    await updateCategory(categoryId: categoryId, isActive: false);
  }
}
