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

  double get totalOutstandingCredit => _customers.fold(0, (sum, c) => sum + c.currentCredit);

  String _searchQuery = '';
  CreditFilter _creditFilter = CreditFilter.all;

  String get searchQuery => _searchQuery;
  CreditFilter get creditFilter => _creditFilter;

  List<Customer> get debtors {
    return _customers.where((c) => c.currentCredit > 0).toList();
  }

  List<Customer> get filteredDebtors {
    final list = debtors;
    final query = _searchQuery.toLowerCase();
    
    return list.where((c) {
      final matchesSearch = c.name.toLowerCase().contains(query) ||
          (c.phone ?? '').contains(query);
      
      bool matchesCredit = true;
      if (_creditFilter == CreditFilter.high) {
        matchesCredit = c.currentCredit >= 5000;
      } else if (_creditFilter == CreditFilter.low) {
        matchesCredit = c.currentCredit < 5000;
      }
      
      return matchesSearch && matchesCredit;
    }).toList();
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

  void setCreditFilter(CreditFilter filter) {
    _creditFilter = filter;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

enum CreditFilter { all, high, low }

