// lib/features/pos/application/pos_provider.dart
import 'package:flutter/foundation.dart' hide Category, Transaction;
import '../../../core/models/entities.dart' hide Product; 
import '../../inventory/data/repositories/product_repository.dart';
import '../../inventory/data/models/product_model.dart';
import '../../inventory/data/models/product_unit_model.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/services/data_sync_service.dart';
import '../../settings/application/settings_provider.dart';
import 'package:utility_store_pos/features/pos/data/models/cart_item.dart';

class PosProvider extends ChangeNotifier {
  final TransactionRepository _transactionRepository;
  final SettingsProvider _settingsProvider;
  final DataSyncService? _syncService;

  // Cart items
  List<CartItem> _cartItems = [];

  // Transaction details
  dynamic _selectedCustomer; 
  String _paymentMethod = 'CASH'; 
  double _discountAmount = 0;
  double _taxPercentage = 0;
  
  // UI State
  int _bulkQuantity = 1;
  bool _isWholesale = false;

  // State
  bool _isProcessing = false;
  String? _error;

  PosProvider(this._transactionRepository, this._settingsProvider, [this._syncService]);

  // Getters
  List<CartItem> get cartItems => _cartItems;
  dynamic get selectedCustomer => _selectedCustomer;
  String get paymentMethod => _paymentMethod;
  double get discountAmount => _discountAmount;
  double get taxPercentage => _taxPercentage;
  int get bulkQuantity => _bulkQuantity;
  bool get isWholesale => _isWholesale;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  @override
  void notifyListeners() {
    if (!_isProcessing) {
      _recalculateProratedRemainders();
    }
    super.notifyListeners();
  }

  void _recalculateProratedRemainders() {
    if (!_settingsProvider.prorateUomRemainders) {
      _resetPiecePrices();
      return;
    }

    final baseIds = _cartItems.map((item) => item.baseVariantId ?? item.variantId).toSet();
    
    for (final bId in baseIds) {
      final itemsForProduct = _cartItems.where((i) => (i.baseVariantId ?? i.variantId) == bId).toList();
      
      CartItem? highestUnitItem;
      for (final item in itemsForProduct) {
        if (item.quantity > 0) {
          if (highestUnitItem == null || item.conversionRate > highestUnitItem.conversionRate) {
            highestUnitItem = item;
          }
        }
      }

      if (highestUnitItem != null && highestUnitItem.conversionRate > 1) {
        final proratedPrice = highestUnitItem.unitPrice / highestUnitItem.conversionRate;
        for (int i = 0; i < _cartItems.length; i++) {
          final item = _cartItems[i];
          if ((item.baseVariantId ?? item.variantId) == bId && item.conversionRate == 1) {
            final baseUnit = item.productUnits.where((u) => u.conversionRate == 1).firstOrNull;
            final cost = baseUnit?.costPrice ?? 0.0;
            if (item.unitPrice != proratedPrice) {
              _cartItems[i] = item.copyWith(
                unitPrice: proratedPrice,
                profitMargin: proratedPrice - cost,
              );
            }
          }
        }
      } else {
        for (int i = 0; i < _cartItems.length; i++) {
          final item = _cartItems[i];
          if ((item.baseVariantId ?? item.variantId) == bId && item.conversionRate == 1) {
             final baseUnit = item.productUnits.where((u) => u.conversionRate == 1).firstOrNull;
             if (baseUnit != null) {
               final stdPrice = _isWholesale ? (baseUnit.wholesalePrice ?? baseUnit.retailPrice) : baseUnit.retailPrice;
               if (item.unitPrice != stdPrice) {
                 _cartItems[i] = item.copyWith(
                   unitPrice: stdPrice,
                   profitMargin: stdPrice - baseUnit.costPrice,
                 );
               }
             }
          }
        }
      }
    }
  }

  void _resetPiecePrices() {
    for (int i = 0; i < _cartItems.length; i++) {
      final item = _cartItems[i];
      if (item.conversionRate == 1) {
         final baseUnit = item.productUnits.where((u) => u.conversionRate == 1).firstOrNull;
         if (baseUnit != null) {
           final stdPrice = _isWholesale ? (baseUnit.wholesalePrice ?? baseUnit.retailPrice) : baseUnit.retailPrice;
           if (item.unitPrice != stdPrice) {
             _cartItems[i] = item.copyWith(
               unitPrice: stdPrice,
               profitMargin: stdPrice - baseUnit.costPrice,
             );
           }
         }
      }
    }
  }

  // Calculations
  double get subtotal =>
      _cartItems.fold(0, (sum, item) => sum + (item.quantity * item.unitPrice));

  double get taxAmount => subtotal * (_taxPercentage / 100);

  double get totalAmount => subtotal + taxAmount - _discountAmount;

  double get total => totalAmount;

  int get itemCount => _cartItems.length;

  // UI Helpers
  void setBulkQuantity(int quantity) {
    _bulkQuantity = quantity;
    notifyListeners();
  }

  void setCustomer(dynamic customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setWholesaleMode(bool? value) {
    _isWholesale = value ?? false;
    
    // Refresh prices for base units in the cart
    for (var i = 0; i < _cartItems.length; i++) {
      final item = _cartItems[i];
      // Only pieces (conversionRate 1) respect the wholesale toggle
      if (item.conversionRate == 1) {
        // Find the base unit/variant in the productUnits
        final baseUnit = item.productUnits.where((u) => u.conversionRate == 1).firstOrNull;
        if (baseUnit != null) {
          final unitPrice = _isWholesale 
              ? (baseUnit.wholesalePrice ?? baseUnit.retailPrice) 
              : baseUnit.retailPrice;
          
          _cartItems[i] = item.copyWith(
            unitPrice: unitPrice,
            profitMargin: unitPrice - baseUnit.costPrice,
          );
        }
      }
    }
    
    notifyListeners();
  }

  // Scanning Integration — Multi-UOM Aware
  Future<bool> handleBarcode(String barcode, ProductRepository repository, {bool isUomEnabled = false}) async {
    try {
      // ── Step 1: Try UOM table first ──
      final productUnit = await repository.getUnitByBarcode(barcode);
      if (productUnit != null) {
        // If UOM is disabled, we only allow scanning of BASE units (conversionRate 1)
        if (isUomEnabled || productUnit.conversionRate == 1) {
          return await _addUomToCart(productUnit, repository, isUomEnabled: isUomEnabled);
        }
      }

      // ── Step 2: Fall back to classic variant barcode ──
      final variant = await repository.getVariantByBarcode(barcode);
      if (variant == null) {
        _error = 'Product not found for barcode: $barcode';
        notifyListeners();
        return false;
      }

      final productWithVariants = await repository.getProductWithVariants(variant.productId);
      if (productWithVariants == null) return false;

      final product = productWithVariants['product'];

      final stockLevel = await repository.getStockLevelByVariantId(variant.id);
      final availableStock = stockLevel?.availablePieces ?? 0;

      if (availableStock <= 0) {
        _error = 'Product out of stock!';
        notifyListeners();
        return false;
      }

      final unitPrice = _isWholesale ? (variant.wholesalePrice ?? variant.retailPrice) : variant.retailPrice;

      addToCart(
        variantId: variant.id,
        productName: product.name,
        productSku: product.baseSku,
        variantName: variant.variantName ?? '',
        unitPrice: unitPrice,
        quantity: _bulkQuantity,
        profitMargin: unitPrice - variant.costPrice,
        availableStock: availableStock,
        productUnits: isUomEnabled ? await repository.getUnitsByProductId(variant.productId) : [],
        // If UOM is enabled, treat this variant as the base unit for itself
        unitId: isUomEnabled ? variant.id : null,
        unitName: isUomEnabled ? (variant.variantName ?? 'Piece') : null,
        baseVariantId: isUomEnabled ? variant.id : null,
      );

      return _error == null;
    } catch (e) {
      _error = 'Error scanning barcode: $e';
      notifyListeners();
      return false;
    }
  }

  /// Add a UOM (ProductUnit) directly to the cart. Stock is tracked in Base Units.
  Future<bool> _addUomToCart(ProductUnit unit, ProductRepository repository, {bool isUomEnabled = true}) async {
    try {
      // We track stock via the base unit for this product
      // Fetch product data
      final prodData = await repository.getProductWithVariants(unit.productId);
      final product = prodData?['product'] as Product?;
      final productName = product?.name ?? unit.productId;
      final productSku = product?.baseSku ?? '';

      final baseUnit = await repository.getBaseUnitByProductId(unit.productId);
      if (baseUnit == null) {
        _error = 'Could not find Base Unit for this product.';
        notifyListeners();
        return false;
      }

      final primaryVariantId = await repository.getPrimaryVariantId(unit.productId);
      final stockLevel = await repository.getStockLevelByVariantId(primaryVariantId ?? baseUnit.id);
      final availableBaseStock = stockLevel?.availablePieces ?? 0;

      // Each unit of this UOM "consumes" conversionRate base stock
      final baseStockRequired = unit.conversionRate * _bulkQuantity;

      if (availableBaseStock < baseStockRequired) {
        final availableUomQty = availableBaseStock ~/ unit.conversionRate;
        _error = 'Insufficient stock. Only $availableUomQty ${unit.unitName}(s) available.';
        notifyListeners();
        return false;
      }

      final unitPrice = _isWholesale
          ? (unit.wholesalePrice ?? unit.retailPrice)
          : unit.retailPrice;

      // Use a composite key for identifying UOM items in the cart
      final cartKey = '${unit.productId}__${unit.id}';

      final existingIndex = _cartItems.indexWhere((item) => item.variantId == cartKey);

      if (existingIndex >= 0) {
        final newQty = _cartItems[existingIndex].quantity + _bulkQuantity;
        final newBaseRequired = unit.conversionRate * newQty;

        if (newBaseRequired > availableBaseStock) {
          final maxQty = availableBaseStock ~/ unit.conversionRate;
          _error = 'Max available: $maxQty ${unit.unitName}(s).';
          notifyListeners();
          return false;
        }
        _cartItems[existingIndex].quantity = newQty;
        _autoUpscale(existingIndex);
      } else {
        _cartItems.add(CartItem(
          id: 'cart_${DateTime.now().millisecondsSinceEpoch}',
          variantId: cartKey, // synthetic key: productId + unitId
          productName: productName,
          productSku: productSku,
          variantName: unit.unitName,
          unitPrice: unitPrice,
          quantity: _bulkQuantity,
          profitMargin: unitPrice - unit.costPrice,
          availableStock: availableBaseStock ~/ unit.conversionRate,
          // UOM-specific fields
          unitId: unit.id,
          unitName: unit.unitName,
          conversionRate: unit.conversionRate,
          baseVariantId: baseUnit.id,
          productUnits: isUomEnabled ? await repository.getUnitsByProductId(unit.productId) : [],
        ));
      }

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error adding UOM to cart: $e';
      notifyListeners();
      return false;
    }
  }

  // Cart Operations
  void addToCart({
    required String variantId,
    required String productName,
    required String productSku,
    required String variantName,
    required double unitPrice,
    required int quantity,
    String? cartonId,
    double profitMargin = 0,
    required int availableStock,
    // Optional UOM fields
    String? unitId,
    String? unitName,
    int conversionRate = 1,
    String? baseVariantId,
    List<ProductUnit> productUnits = const [],
  }) {
    final existingIndex =
        _cartItems.indexWhere((item) => item.variantId == variantId);

    if (existingIndex >= 0) {
      final newQty = _cartItems[existingIndex].quantity + quantity;
      if (newQty > availableStock) {
        _error = 'Insufficient stock. Only $availableStock available.';
      } else {
        _cartItems[existingIndex].quantity = newQty;
        _autoUpscale(existingIndex);
        _error = null;
      }
    } else {
      if (quantity > availableStock) {
        _error = 'Insufficient stock. Only $availableStock available.';
      } else {
        _cartItems.add(
          CartItem(
            id: 'cart_${DateTime.now().millisecondsSinceEpoch}',
            variantId: variantId,
            productName: productName,
            productSku: productSku,
            variantName: variantName,
            unitPrice: unitPrice,
            quantity: quantity,
            cartonId: cartonId,
            profitMargin: profitMargin,
            availableStock: availableStock,
            unitId: unitId,
            unitName: unitName,
            conversionRate: conversionRate,
            baseVariantId: baseVariantId,
            productUnits: productUnits,
          ),
        );
        _autoUpscale(_cartItems.length - 1);
        _error = null;
      }
    }

    notifyListeners();
  }

  Future<void> changeItemUnit(String cartId, ProductUnit newUnit) async {
    final index = _cartItems.indexWhere((item) => item.id == cartId);
    if (index >= 0) {
      final item = _cartItems[index];
      
      // Calculate new pricing
      // Only pieces (conversionRate 1) respect the wholesale toggle
      final useWholesale = _isWholesale && newUnit.conversionRate == 1;
      final unitPrice = useWholesale 
          ? (newUnit.wholesalePrice ?? newUnit.retailPrice) 
          : newUnit.retailPrice;

      _cartItems[index] = item.copyWith(
        unitId: newUnit.id,
        unitName: newUnit.unitName,
        conversionRate: newUnit.conversionRate,
        unitPrice: unitPrice,
        variantName: newUnit.unitName,
        profitMargin: unitPrice - newUnit.costPrice,
      );
      
      notifyListeners();
    }
  }

  void _autoUpscale(int index) {
    if (index < 0 || index >= _cartItems.length) return;
    var item = _cartItems[index];
    if (!item.isUomItem || item.productUnits.isEmpty) return;

    // Only upscale from base unit (conversionRate 1) to avoid confusing users
    if (item.conversionRate != 1) return;

    // Find the highest unit that divides the current quantity
    final sortedUnits = List<ProductUnit>.from(item.productUnits)
      ..sort((a, b) => b.conversionRate.compareTo(a.conversionRate));

    for (final unit in sortedUnits) {
      if (unit.conversionRate > 1 && item.quantity >= unit.conversionRate) {
        // We can upscale! (e.g., 8 pieces -> 1 Pet + 2 Pieces remaining)
        // BUT we only upscale the WHOLE units.
        final wholeUnits = item.quantity ~/ unit.conversionRate;
        final remainder = item.quantity % unit.conversionRate;

        if (wholeUnits > 0) {
          final unitPrice = _isWholesale 
              ? (unit.wholesalePrice ?? unit.retailPrice) 
              : unit.retailPrice;

          final upscaledId = '${unit.productId}__${unit.id}';
          final existingUnitIdx = _cartItems.indexWhere((it) => it.variantId == upscaledId);

          if (existingUnitIdx >= 0 && existingUnitIdx != index) {
            // Merge into existing bulk row
            _cartItems[existingUnitIdx].quantity += wholeUnits;
            _cartItems[index].quantity = remainder;
          } else {
            // Transform current row or add new bulk row
            if (remainder == 0) {
              // Exact match, transform this row
              _cartItems[index] = item.copyWith(
                variantId: upscaledId,
                unitId: unit.id,
                unitName: unit.unitName,
                conversionRate: unit.conversionRate,
                quantity: wholeUnits,
                unitPrice: unitPrice,
                variantName: unit.unitName,
                profitMargin: unitPrice - unit.costPrice,
              );
            } else {
              // Mixed quantities: 6 pieces become 1 Pet + remainder 2 pieces stay here
              _cartItems.add(CartItem(
                id: 'cart_${DateTime.now().microsecondsSinceEpoch}',
                variantId: upscaledId,
                productName: item.productName,
                productSku: item.productSku,
                variantName: unit.unitName,
                unitPrice: unitPrice,
                quantity: wholeUnits,
                profitMargin: unitPrice - unit.costPrice,
                availableStock: item.availableStock,
                unitId: unit.id,
                unitName: unit.unitName,
                conversionRate: unit.conversionRate,
                baseVariantId: item.baseVariantId,
                productUnits: item.productUnits,
              ));
              // Update current piece row to just the remainder
              _cartItems[index].quantity = remainder;
            }
          }
          
          if (remainder == 0 && existingUnitIdx >= 0 && existingUnitIdx != index) {
            // We merged the entire row, remove the empty piece row
            _cartItems.removeAt(index);
          }
          
          break; // Stop after first successful upscale
        }
      }
    }
  }

  void incrementQuantity(String variantId) {
    final index = _cartItems.indexWhere((item) => item.variantId == variantId);
    if (index >= 0) {
      final item = _cartItems[index];
      if (item.quantity < item.availableStock) {
        _cartItems[index].quantity += 1;
        if (item.conversionRate == 1) {
          _autoUpscale(index);
        }
        _error = null;
      } else {
        _error = 'Insufficient stock!';
      }
      notifyListeners();
    }
  }

  void decrementQuantity(String variantId) {
    final index = _cartItems.indexWhere((item) => item.variantId == variantId);
    if (index >= 0) {
      final item = _cartItems[index];
      if (item.quantity > 1) {
        _cartItems[index].quantity -= 1;
      } else {
        // Downscale Logic: 1 Pet -> 5 Pieces (if conversion is 6)
        if (item.isUomItem && item.conversionRate > 1) {
          final baseUnit = item.productUnits.where((u) => u.conversionRate == 1).firstOrNull;
          if (baseUnit != null) {
            final downscaledId = '${baseUnit.productId}__${baseUnit.id}';
            final piecesToRestore = item.conversionRate - 1;
            
            final existingPieceIdx = _cartItems.indexWhere((it) => it.variantId == downscaledId);
            if (existingPieceIdx >= 0) {
              _cartItems[existingPieceIdx].quantity += piecesToRestore;
            } else {
              final unitPrice = _isWholesale ? (baseUnit.wholesalePrice ?? baseUnit.retailPrice) : baseUnit.retailPrice;
              _cartItems.add(CartItem(
                id: 'cart_${DateTime.now().microsecondsSinceEpoch}',
                variantId: downscaledId,
                productName: item.productName,
                productSku: item.productSku,
                variantName: baseUnit.unitName,
                unitPrice: unitPrice,
                quantity: piecesToRestore,
                profitMargin: unitPrice - baseUnit.costPrice,
                availableStock: item.availableStock * item.conversionRate,
                unitId: baseUnit.id,
                unitName: baseUnit.unitName,
                conversionRate: 1,
                baseVariantId: baseUnit.id,
                productUnits: item.productUnits,
              ));
            }
            _cartItems.removeAt(index);
          } else {
            _cartItems.removeAt(index);
          }
        } else {
          _cartItems.removeAt(index);
        }
      }
      notifyListeners();
    }
  }

  void removeFromCart(String variantId) {
    _cartItems.removeWhere((item) => item.variantId == variantId);
    notifyListeners();
  }
  
  void removeProduct(dynamic product) {
    removeFromCart(product.id.toString());
  }

  void clearCart() {
    _cartItems.clear();
    _selectedCustomer = null;
    _paymentMethod = 'CASH';
    _discountAmount = 0;
    _bulkQuantity = 1;
    notifyListeners();
  }

  // Payment & Discount
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    _error = null;
    notifyListeners();
  }

  void setDiscountAmount(double amount) {
    _discountAmount = amount;
    notifyListeners();
  }

  // Checkout
  Future<String?> processCheckout({
    double? cashPaid,
    double? creditAmount,
    DateTime? dueDate,
    required Function(Transaction transaction) onSuccess,
    required Function(dynamic error) onError,
  }) async {
    if (_cartItems.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final transactionId = 'txn_${DateTime.now().microsecondsSinceEpoch}';
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      
      final tx = Transaction(
        id: transactionId,
        invoiceNumber: invoiceNumber,
        customerId: _selectedCustomer?.id,
        totalAmount: subtotal,
        discount: _discountAmount,
        tax: taxAmount,
        finalAmount: totalAmount,
        cashPaid: cashPaid ?? totalAmount,
        creditAmount: creditAmount ?? 0.0,
        paymentMethod: _paymentMethod,
        paymentStatus: (creditAmount ?? 0.0) > 0 ? 'PARTIAL' : 'COMPLETED',
        createdAt: DateTime.now(),
      );

      int microsecondOffset = 0;
      final txItems = _cartItems.map<TransactionItem>((CartItem item) {
        microsecondOffset++;
        return TransactionItem(
          id: 'txi_${DateTime.now().microsecondsSinceEpoch + microsecondOffset}_${item.variantId.replaceAll('__', '_')}',
          transactionId: transactionId,
          variantId: item.baseVariantId ?? item.variantId,
          quantity: item.isUomItem ? (item.quantity * item.conversionRate) : item.quantity,
          priceAtTime: item.unitPrice,
          costAtTime: item.unitPrice - item.profitMargin,
          subtotal: item.subtotal,
          unitId: item.unitId,
          unitName: item.unitName ?? item.variantName,
        );
      }).toList();

      final savedTx = await _transactionRepository.insertTransaction(
        transaction: tx,
        items: txItems,
        dueDate: dueDate,
      );

      _isProcessing = false;
      notifyListeners();

      onSuccess(savedTx);
      _syncService?.notifyMobileUpdate();
      clearCart();

      return savedTx.id;
    } catch (e) {
      _error = 'Checkout failed: $e';
      _isProcessing = false;
      notifyListeners();
      onError(e);
      return null;
    }
  }
}
