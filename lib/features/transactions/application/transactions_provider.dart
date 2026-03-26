import 'package:flutter/material.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../core/models/entities.dart';
import '../../../core/repositories/transaction_repository.dart';

enum TransactionFilter { today, last7Days, lastMonth, custom }

class TransactionsProvider extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();
  final DataSyncService? _syncService;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  TransactionFilter _currentFilter = TransactionFilter.today;
  DateTimeRange? _customRange;
  String? _selectedPaymentMethod;
  String? _selectedCustomer;

  List<Transaction> get transactions {
    Iterable<Transaction> filtered = _transactions;
    
    if (_selectedPaymentMethod != null && _selectedPaymentMethod != 'ALL') {
      filtered = filtered.where((tx) => tx.paymentMethod.toUpperCase() == _selectedPaymentMethod);
    }
    
    if (_selectedCustomer != null && _selectedCustomer != 'ALL') {
      if (_selectedCustomer == 'Walk-in') {
        filtered = filtered.where((tx) => tx.customerName == null || tx.customerName!.isEmpty);
      } else {
        filtered = filtered.where((tx) => tx.customerName == _selectedCustomer);
      }
    }
    
    return filtered.toList();
  }

  // Get unique customers from currently loaded transactions for the dropdown filter
  List<String> get availableCustomers {
    final Set<String> customers = {};
    for (var tx in _transactions) {
      if (tx.customerName != null && tx.customerName!.isNotEmpty) {
        customers.add(tx.customerName!);
      } else {
        customers.add('Walk-in');
      }
    }
    return customers.toList()..sort();
  }

  bool get isLoading => _isLoading;
  TransactionFilter get currentFilter => _currentFilter;
  DateTimeRange? get customRange => _customRange;
  String? get selectedPaymentMethod => _selectedPaymentMethod;
  String? get selectedCustomer => _selectedCustomer;

  TransactionsProvider({DataSyncService? syncService}) : _syncService = syncService {
    loadTransactions();
    _syncService?.addListener(_onSyncUpdate);
  }

  void _onSyncUpdate() {
    print('TransactionsProvider: Sync update detected, reloading...');
    loadTransactions();
  }

  @override
  void dispose() {
    _syncService?.removeListener(_onSyncUpdate);
    super.dispose();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      DateTime start;
      DateTime end = DateTime(now.year, now.month, now.day + 1);

      switch (_currentFilter) {
        case TransactionFilter.today:
          start = DateTime(now.year, now.month, now.day);
          break;
        case TransactionFilter.last7Days:
          start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
          break;
        case TransactionFilter.lastMonth:
          start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
          break;
        case TransactionFilter.custom:
          if (_customRange != null) {
            start = _customRange!.start;
            end = _customRange!.end.add(const Duration(days: 1)); // Include the end day
          } else {
            start = DateTime(now.year, now.month, now.day);
          }
          break;
      }

      _transactions = await _repository.getTransactionsByDateRange(start, end);
    } catch (e) {
      _transactions = [];
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(TransactionFilter filter, {DateTimeRange? range}) {
    _currentFilter = filter;
    if (filter == TransactionFilter.custom && range != null) {
      _customRange = range;
    }
    loadTransactions();
  }

  void setPaymentMethodFilter(String? method) {
    _selectedPaymentMethod = method?.toUpperCase();
    notifyListeners();
  }

  void setCustomerFilter(String? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  Future<Transaction?> getTransactionById(String id) async {
    return _repository.getTransactionById(id);
  }

  Future<List<Map<String, Object?>>> getTransactionItems(String txId) async {
    return _repository.getItemsForTransaction(txId);
  }

  Future<void> processReturn({
    required Transaction transaction,
    required List<Map<String, Object?>> items,
    required Map<String, int> quantitiesToReturn,
  }) async {
    await _repository.returnItemsFromTransaction(
      transaction: transaction,
      items: items,
      quantitiesToReturn: quantitiesToReturn,
    );
    // Reload transactions to reflect updated totals and status
    await loadTransactions();
  }
}
