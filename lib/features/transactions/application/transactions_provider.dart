import 'package:flutter/material.dart';
import '../../../core/models/entities.dart';
import '../../../core/repositories/transaction_repository.dart';

enum TransactionFilter { today, last7Days, lastMonth, custom }

class TransactionsProvider extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  TransactionFilter _currentFilter = TransactionFilter.today;
  DateTimeRange? _customRange;
  String? _selectedPaymentMethod;

  List<Transaction> get transactions {
    if (_selectedPaymentMethod == null || _selectedPaymentMethod == 'ALL') {
      return _transactions;
    }
    return _transactions.where((tx) => tx.paymentMethod.toUpperCase() == _selectedPaymentMethod).toList();
  }

  bool get isLoading => _isLoading;
  TransactionFilter get currentFilter => _currentFilter;
  DateTimeRange? get customRange => _customRange;
  String? get selectedPaymentMethod => _selectedPaymentMethod;

  TransactionsProvider() {
    loadTransactions();
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

  Future<List<Map<String, Object?>>> getTransactionItems(String txId) async {
    return _repository.getItemsForTransaction(txId);
  }
}
