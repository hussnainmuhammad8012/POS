import 'package:flutter/material.dart';

import '../../../core/models/entities.dart';

class CustomersProvider extends ChangeNotifier {
  final List<Customer> _customers = [];

  List<Customer> get customers => List.unmodifiable(_customers);

  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  List<Customer> get filteredCustomers {
    if (_searchQuery.isEmpty) return customers;
    return _customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (c.phone ?? '').contains(_searchQuery),
        )
        .toList();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void upsertCustomer(Customer customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _customers[index] = customer;
    } else {
      _customers.add(customer);
    }
    notifyListeners();
  }
}

