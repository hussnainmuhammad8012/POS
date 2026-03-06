// lib/features/inventory/application/inventory_provider.dart
import 'package:flutter/foundation.dart' hide Category;
import '../data/models/category_model.dart';
import '../data/models/product_model.dart';
import '../data/models/product_variant_model.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/product_repository.dart';

class InventoryProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepository;
  final ProductRepository _productRepository;

  // State
  List<Category> _categories = [];
  List<Product> _products = [];
  
  // Filters
  String? _selectedCategoryId;
  String _searchQuery = '';
  double _minPrice = 0;
  double _maxPrice = double.infinity;
  int _minStock = 0;
  int _maxStock = 999999;
  bool _showLowStockOnly = false;

  // Loading states
  bool _isLoading = false;
  String? _error;

  InventoryProvider({
    required CategoryRepository categoryRepository,
    required ProductRepository productRepository,
  })  : _categoryRepository = categoryRepository,
        _productRepository = productRepository;

  // Getters
  List<Category> get categories => _categories;
  List<Product> get filteredProducts => _getFilteredProducts();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategoryId => _selectedCategoryId;

  // Initialize
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await loadCategories();
      await loadProducts();
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize inventory: $e';
    }
    _setLoading(false);
  }

  // Load categories with hierarchy
  Future<void> loadCategories() async {
    try {
      _categories = await _categoryRepository.getAllCategoriesHierarchy();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load categories: $e';
      notifyListeners();
    }
  }

  // Load products
  Future<void> loadProducts() async {
    try {
      _products = await _productRepository.getAllProducts();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load products: $e';
      notifyListeners();
    }
  }

  // CRUD Operations - Categories
  Future<String> createCategory({
    required String name,
    String? parentId,
    String? description,
    String? iconName,
  }) async {
    try {
      final id = await _categoryRepository.createCategory(
        name: name,
        parentId: parentId,
        description: description,
        iconName: iconName,
      );
      await loadCategories();
      return id;
    } catch (e) {
      _error = 'Failed to create category: $e';
      notifyListeners();
      rethrow;
    }
  }

  // CRUD Operations - Products
  Future<String> createProduct({
    required String categoryId,
    required String name,
    required String baseSku,
    String? description,
    String? mainImagePath,
    required String unitType,
  }) async {
    try {
      final id = await _productRepository.createProduct(
        categoryId: categoryId,
        name: name,
        baseSku: baseSku,
        description: description,
        mainImagePath: mainImagePath,
        unitType: unitType,
      );
      await loadProducts();
      return id;
    } catch (e) {
      _error = 'Failed to create product: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<String> createProductVariant({
    required String productId,
    String? variantName,
    required String sku,
    String? barcode,
    required double costPrice,
    required double retailPrice,
    double? wholesalePrice,
    double? mrp,
    String? variantImagePath,
    int initialStock = 0,
    int lowStockThreshold = 10,
  }) async {
    try {
      final id = await _productRepository.createProductVariant(
        productId: productId,
        variantName: variantName,
        sku: sku,
        barcode: barcode,
        costPrice: costPrice,
        retailPrice: retailPrice,
        wholesalePrice: wholesalePrice,
        mrp: mrp,
        variantImagePath: variantImagePath,
        initialStock: initialStock,
        lowStockThreshold: lowStockThreshold,
      );
      await loadProducts();
      return id;
    } catch (e) {
      _error = 'Failed to create variant: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Filtering
  void setSelectedCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Private helper for filtering
  List<Product> _getFilteredProducts() {
    var filtered = _products;
    if (_selectedCategoryId != null) {
      filtered = filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) => 
        p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.baseSku.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    return filtered;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
