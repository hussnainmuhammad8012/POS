import 'package:flutter/material.dart';

import '../../../core/models/entities.dart';

class InventoryProvider extends ChangeNotifier {
  final List<Category> _categories = [];
  final List<Product> _products = [];

  List<Category> get categories => List.unmodifiable(_categories);
  List<Product> get products => List.unmodifiable(_products);

  String _searchQuery = '';
  int? _selectedCategoryId;

  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;

  List<Product> get filteredProducts {
    return _products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.barcode ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setSelectedCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void upsertCategory(Category category) {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index >= 0) {
      _categories[index] = category;
    } else {
      _categories.add(category);
    }
    notifyListeners();
  }

  void deleteCategory(Category category) {
    _categories.removeWhere((c) => c.id == category.id);
    notifyListeners();
  }

  void upsertProduct(Product product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
    } else {
      _products.add(product);
    }
    notifyListeners();
  }

  void deleteProduct(Product product) {
    _products.removeWhere((p) => p.id == product.id);
    notifyListeners();
  }
}

