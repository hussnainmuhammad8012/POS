import 'package:flutter/material.dart';
import '../../features/inventory/data/repositories/product_repository.dart';
import '../../core/repositories/customer_repository.dart';
import '../../features/inventory/data/models/product_summary_model.dart';
import '../../core/models/entities.dart';

enum SearchResultType { product, customer }

class GlobalSearchResult {
  final String id;
  final String title;
  final String? subtitle;
  final SearchResultType type;
  final dynamic originalObject;

  GlobalSearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.originalObject,
  });
}

class GlobalSearchProvider extends ChangeNotifier {
  final ProductRepository _productRepository;
  final CustomerRepository _customerRepository;

  GlobalSearchProvider({
    required ProductRepository productRepository,
    required CustomerRepository customerRepository,
  })  : _productRepository = productRepository,
        _customerRepository = customerRepository;

  List<GlobalSearchResult> _results = [];
  bool _isLoading = false;
  String _query = '';

  List<GlobalSearchResult> get results => _results;
  bool get isLoading => _isLoading;
  String get query => _query;

  Future<void> search(String query) async {
    _query = query;
    if (query.length < 2) {
      _results = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final products = await _productRepository.getAllProductSummaries(searchQuery: query);
      final customers = await _customerRepository.searchCustomers(query);

      final productResults = products.map((p) => GlobalSearchResult(
            id: p.product.id!,
            title: p.product.name,
            subtitle: 'SKU: ${p.product.baseSku} • Rs ${p.minPrice.toStringAsFixed(2)}',
            type: SearchResultType.product,
            originalObject: p,
          ));

      final customerResults = customers.map((c) => GlobalSearchResult(
            id: c.id!,
            title: c.name,
            subtitle: 'Phone: ${c.phone ?? 'N/A'} • Credit: Rs ${c.currentCredit.toStringAsFixed(2)}',
            type: SearchResultType.customer,
            originalObject: c,
          ));

      _results = [...productResults, ...customerResults];
    } catch (e) {
      debugPrint('Error during global search: $e');
      _results = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _query = '';
    _results = [];
    notifyListeners();
  }
}
