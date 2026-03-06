import 'package:flutter/foundation.dart';
import '../../../core/models/entities.dart';
import '../../../core/repositories/credit_ledger_repository.dart';

class CreditLedgerProvider extends ChangeNotifier {
  final CreditLedgerRepository _repository;

  CreditLedgerProvider(this._repository);

  List<CreditLedger> _ledgers = [];
  bool _isLoading = false;
  String? _error;

  List<CreditLedger> get ledgers => _ledgers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLedgers(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ledgers = await _repository.getLedgersByCustomer(customerId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPayment({
    required String customerId,
    required double amount,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final ledger = CreditLedger(
        id: 'pay_${DateTime.now().microsecondsSinceEpoch}',
        customerId: customerId,
        type: 'PAYMENT',
        amount: amount,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await _repository.insert(ledger);
      await loadLedgers(customerId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
