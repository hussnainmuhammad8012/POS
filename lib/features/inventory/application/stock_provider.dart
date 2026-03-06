// lib/features/inventory/application/stock_provider.dart
import 'package:flutter/foundation.dart';
import '../data/models/carton_model.dart';
import '../data/models/stock_level_model.dart';
import '../data/models/stock_movement_model.dart';
import '../data/repositories/carton_repository.dart';
import '../data/repositories/stock_movement_repository.dart';

class StockProvider extends ChangeNotifier {
  final CartonRepository _cartonRepository;
  final StockMovementRepository _movementRepository;

  // State
  List<Carton> _cartons = [];
  List<StockMovement> _movements = [];

  // Filters
  String? _selectedProductVariantId;
  String _movementTypeFilter = 'ALL';
  DateTime _dateFrom = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dateTo = DateTime.now();

  // Loading states
  bool _isLoading = false;
  String? _error;

  StockProvider({
    required CartonRepository cartonRepository,
    required StockMovementRepository movementRepository,
  })  : _cartonRepository = cartonRepository,
        _movementRepository = movementRepository;

  // Getters
  List<Carton> get cartons => _cartons;
  List<StockMovement> get filteredMovements => _getFilteredMovements();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await loadMovements();
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize stock: $e';
    }
    _setLoading(false);
  }

  // Load stock movements
  Future<void> loadMovements() async {
    try {
      _movements = await _movementRepository.getAllMovements(
        startDate: _dateFrom,
        endDate: _dateTo,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load movements: $e';
      notifyListeners();
    }
  }

  // Load cartons for a variant
  Future<void> loadCartons(String variantId) async {
    try {
      _cartons = await _cartonRepository.getCartonsByVariant(variantId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load cartons: $e';
      notifyListeners();
    }
  }

  // Receive new carton
  Future<String> receiveCarton({
    required String productVariantId,
    required String cartonNumber,
    required int piecesPerCarton,
    required double costPerPiece,
    required int receivedQuantity,
    DateTime? expiryDate,
    String? supplierBatchId,
    String? storageLocation,
    String? notes,
  }) async {
    try {
      final id = await _cartonRepository.receiveCarton(
        productVariantId: productVariantId,
        cartonNumber: cartonNumber,
        piecesPerCarton: piecesPerCarton,
        costPerPiece: costPerPiece,
        receivedQuantity: receivedQuantity,
        expiryDate: expiryDate,
        supplierBatchId: supplierBatchId,
        storageLocation: storageLocation,
        notes: notes,
      );
      await loadMovements();
      return id;
    } catch (e) {
      _error = 'Failed to receive carton: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Record manual stock adjustment
  Future<void> recordAdjustment({
    required String productVariantId,
    required int quantityAdjustment,
    required String reason,
    String? notes,
  }) async {
    try {
      await _movementRepository.recordAdjustment(
        productVariantId: productVariantId,
        quantityAdjustment: quantityAdjustment,
        reason: reason,
        notes: notes,
      );
      await loadMovements();
    } catch (e) {
      _error = 'Failed to record adjustment: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Filtering
  void setMovementTypeFilter(String type) {
    _movementTypeFilter = type;
    notifyListeners();
  }

  void setDateRange(DateTime from, DateTime to) {
    _dateFrom = from;
    _dateTo = to;
    notifyListeners();
  }

  // Private helper for filtering movements
  List<StockMovement> _getFilteredMovements() {
    var filtered = _movements;
    if (_movementTypeFilter != 'ALL') {
      filtered = filtered.where((m) => m.movementType == _movementTypeFilter).toList();
    }
    if (_selectedProductVariantId != null) {
      filtered = filtered.where((m) => m.productVariantId == _selectedProductVariantId).toList();
    }
    return filtered;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
