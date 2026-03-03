import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/app_database.dart';
import '../models/entities.dart';

class CategoryRepository {
  Database get _db => AppDatabase.instance.db;

  Future<List<Category>> getAll() async {
    final rows = await _db.query(
      'categories',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<Category> insert(Category category) async {
    final id = await _db.insert('categories', {
      'name': category.name,
      'description': category.description,
      'icon_name': category.iconName,
      'created_at': category.createdAt.toIso8601String(),
    });
    return category.copyWith(id: id);
  }

  Future<Category> update(Category category) async {
    if (category.id == null) {
      throw ArgumentError('Category id is required for update');
    }
    await _db.update(
      'categories',
      {
        'name': category.name,
        'description': category.description,
        'icon_name': category.iconName,
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return category;
  }

  Future<void> delete(int id) async {
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Category _fromRow(Map<String, Object?> row) {
    return Category(
      id: row['id'] as int,
      name: row['name'] as String,
      description: row['description'] as String?,
      iconName: row['icon_name'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

