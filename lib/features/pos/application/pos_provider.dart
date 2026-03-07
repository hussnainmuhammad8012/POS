// lib/features/pos/application/pos_provider.dart
import 'package:flutter/foundation.dart' hide Category, Transaction;
import '../../../core/models/entities.dart'; 
import '../../inventory/data/repositories/product_repository.dart';

import '../../../core/repositories/transaction_repository.dart';

class PosProvider extends ChangeNotifier {
  final TransactionRepository _transactionRepository;

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

  PosProvider(this._transactionRepository);

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
    notifyListeners();
  }

  // Scanning Integration
  Future<bool> handleBarcode(String barcode, ProductRepository repository) async {
    try {
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
        variantName: variant.variantName ?? '',
        unitPrice: unitPrice,
        quantity: _bulkQuantity,
        profitMargin: unitPrice - variant.costPrice,
        availableStock: availableStock,
      );

      return _error == null;
    } catch (e) {
      _error = 'Error scanning barcode: $e';
      notifyListeners();
      return false;
    }
  }

  // Cart Operations
  void addToCart({
    required String variantId,
    required String productName,
    required String variantName,
    required double unitPrice,
    required int quantity,
    String? cartonId,
    double profitMargin = 0,
    required int availableStock,
  }) {
    final existingIndex =
        _cartItems.indexWhere((item) => item.variantId == variantId);

    if (existingIndex >= 0) {
      final newQty = _cartItems[existingIndex].quantity + quantity;
      if (newQty > availableStock) {
        _error = 'Insufficient stock. Only $availableStock available.';
      } else {
        _cartItems[existingIndex].quantity = newQty;
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
            variantName: variantName,
            unitPrice: unitPrice,
            quantity: quantity,
            cartonId: cartonId,
            profitMargin: profitMargin,
            availableStock: availableStock,
          ),
        );
        _error = null;
      }
    }

    notifyListeners();
  }

  void incrementQuantity(String variantId) {
    final index = _cartItems.indexWhere((item) => item.variantId == variantId);
    if (index >= 0) {
      if (_cartItems[index].quantity < _cartItems[index].availableStock) {
        _cartItems[index].quantity += 1;
        _error = null;
      } else {
        _error = 'Cannot exceed available stock of ${_cartItems[index].availableStock}.';
      }
      notifyListeners();
    }
  }

  void decrementQuantity(String variantId) {
    final index = _cartItems.indexWhere((item) => item.variantId == variantId);
    if (index >= 0) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity -= 1;
      } else {
        _cartItems.removeAt(index);
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

      final txItems = _cartItems.map((item) => TransactionItem(
        id: 'txi_${DateTime.now().microsecondsSinceEpoch}_${item.variantId}',
        transactionId: transactionId,
        variantId: item.variantId,
        quantity: item.quantity,
        priceAtTime: item.unitPrice,
        costAtTime: item.unitPrice - item.profitMargin, // Assuming profitMargin = unitPrice - costPrice
        subtotal: item.subtotal,
      )).toList();

      final savedTx = await _transactionRepository.insertTransaction(
        transaction: tx,
        items: txItems,
        dueDate: dueDate,
      );

      _isProcessing = false;
      notifyListeners();

      onSuccess(savedTx);
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

class CartItem {
  final String id;
  final String variantId;
  final String productName;
  final String variantName;
  final double unitPrice;
  int quantity;
  final String? cartonId;
  final double profitMargin;
  final int availableStock;

  CartItem({
    required this.id,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.unitPrice,
    required this.quantity,
    this.cartonId,
    required this.profitMargin,
    required this.availableStock,
  });

  double get subtotal => unitPrice * quantity;
}
