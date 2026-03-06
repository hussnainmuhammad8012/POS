import 'package:flutter/material.dart';

import '../../../core/models/entities.dart';
import '../../../core/repositories/customer_repository.dart';

class CustomersProvider extends ChangeNotifier {
  final CustomerRepository _repository;
  
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;

  CustomersProvider({required CustomerRepository repository}) 
      : _repository = repository {
    loadCustomers();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Customer> get customers => List.unmodifiable(_customers);

  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  List<Customer> get filteredCustomers {
    if (_searchQuery.isEmpty) return customers;
    
    final query = _searchQuery.toLowerCase();
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            (c.phone ?? '').contains(query) ||
            (c.whatsappNumber ?? '').contains(query))
        .toList();
  }

  Future<void> loadCustomers() async {
    _setLoading(true);
    try {
      _customers = await _repository.getAll();
      _error = null;
    } catch (e) {
      _error = 'Failed to load customers: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      final inserted = await _repository.insert(customer);
      _customers.add(inserted);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add customer: $e';
      rethrow;
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      final updated = await _repository.update(customer);
      final index = _customers.indexWhere((c) => c.id == updated.id);
      if (index >= 0) {
        _customers[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update customer: $e';
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _repository.delete(id);
      _customers.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete customer: $e';
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

