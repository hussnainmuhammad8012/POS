import 'package:flutter/material.dart';

import '../../../core/models/entities.dart';
import '../../../core/repositories/supplier_repository.dart';
import '../../../core/services/data_sync_service.dart';

class SuppliersProvider extends ChangeNotifier {
  final SupplierRepository _repository;
  final DataSyncService? _syncService;
  
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';

  SuppliersProvider({
    required SupplierRepository repository,
    DataSyncService? syncService,
  })  : _repository = repository,
        _syncService = syncService {
    loadSuppliers();
    _syncService?.addListener(loadSuppliers);
  }

  @override
  void dispose() {
    _syncService?.removeListener(loadSuppliers);
    super.dispose();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Supplier> get suppliers => List.unmodifiable(_suppliers);

  double get totalOutstandingDue => _suppliers.fold(0, (sum, s) => sum + s.currentDue);

  String get searchQuery => _searchQuery;

  List<Supplier> get filteredSuppliers {
    final query = _searchQuery.toLowerCase();
    
    return _suppliers.where((s) {
      final matchesSearch = s.name.toLowerCase().contains(query) ||
          (s.phone ?? '').contains(query);
      return matchesSearch;
    }).toList();
  }

  Future<void> loadSuppliers() async {
    _setLoading(true);
    try {
      _suppliers = await _repository.getAll();
      _error = null;
    } catch (e) {
      _error = 'Failed to load suppliers: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      final inserted = await _repository.insert(supplier);
      _suppliers.add(inserted);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add supplier: $e';
      rethrow;
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      final updated = await _repository.update(supplier);
      final index = _suppliers.indexWhere((s) => s.id == updated.id);
      if (index >= 0) {
        _suppliers[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update supplier: $e';
      rethrow;
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _repository.delete(id);
      _suppliers.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete supplier: $e';
      rethrow;
    }
  }

  // --- LEDGER OPERATIONS ---

  Future<List<SupplierLedger>> getLedger(String supplierId) async {
    try {
      return await _repository.getLedger(supplierId);
    } catch (e) {
      _error = 'Failed to load ledger: $e';
      rethrow;
    }
  }

  Future<void> recordPayment(String supplierId, double amount, {String? notes}) async {
    try {
      final entry = SupplierLedger(
        id: 'ledg_${DateTime.now().microsecondsSinceEpoch}',
        supplierId: supplierId,
        type: 'PAYMENT',
        amount: amount,
        notes: notes ?? 'Manual Payment Recorded',
        createdAt: DateTime.now(),
      );
      await _repository.addLedgerEntry(entry);
      // Reload suppliers to get updated currentDue
      await loadSuppliers();
    } catch (e) {
      _error = 'Failed to record payment: $e';
      rethrow;
    }
  }

  Future<void> recordPurchase(String supplierId, double amount, {String? referenceId, String? notes, DateTime? dueDate}) async {
    try {
      final entry = SupplierLedger(
        id: 'ledg_${DateTime.now().microsecondsSinceEpoch}',
        supplierId: supplierId,
        referenceId: referenceId,
        type: 'PURCHASE',
        amount: amount,
        dueDate: dueDate,
        notes: notes ?? 'Stock Purchase',
        createdAt: DateTime.now(),
      );
      await _repository.addLedgerEntry(entry);
      await loadSuppliers();
    } catch (e) {
      _error = 'Failed to record purchase: $e';
      rethrow;
    }
  }

  Future<void> addSystemNote(String supplierId, String notes) async {
    try {
      final entry = SupplierLedger(
        id: 'ledg_${DateTime.now().microsecondsSinceEpoch}',
        supplierId: supplierId,
        type: 'SYSTEM_NOTE',
        amount: 0.0, // Notes don't change financial balances
        notes: notes,
        createdAt: DateTime.now(),
      );
      await _repository.addLedgerEntry(entry);
      // System notes don't change balances, but reloading ensures fresh state if UI needs it
      notifyListeners(); 
    } catch (e) {
      _error = 'Failed to add system note: $e';
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
