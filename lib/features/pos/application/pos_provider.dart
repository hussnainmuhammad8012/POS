// lib/features/pos/application/pos_provider.dart
import 'package:flutter/foundation.dart' hide Category, Transaction;
import '../../../core/models/entities.dart'; 
import '../../inventory/data/repositories/product_repository.dart';

class PosProvider extends ChangeNotifier {
  // Cart items
  List<CartItem> _cartItems = [];

  // Transaction details
  dynamic _selectedCustomer; 
  String _paymentMethod = 'CASH'; 
  double _discountAmount = 0;
  double _taxPercentage = 0;
  
  // UI State
  int _bulkQuantity = 1;

  // State
  bool _isProcessing = false;
  String? _error;

  PosProvider();

  // Getters
  List<CartItem> get cartItems => _cartItems;
  dynamic get selectedCustomer => _selectedCustomer;
  String get paymentMethod => _paymentMethod;
  double get discountAmount => _discountAmount;
  double get taxPercentage => _taxPercentage;
  int get bulkQuantity => _bulkQuantity;
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

      addToCart(
        variantId: variant.id,
        productName: product.name,
        variantName: variant.variantName ?? '',
        unitPrice: variant.retailPrice,
        quantity: _bulkQuantity,
        profitMargin: variant.retailPrice - variant.costPrice,
      );

      _error = null;
      return true;
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
  }) {
    final existingIndex =
        _cartItems.indexWhere((item) => item.variantId == variantId);

    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += quantity;
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
        ),
      );
    }

    _error = null;
    notifyListeners();
  }

  void incrementQuantity(String variantId) {
    final index = _cartItems.indexWhere((item) => item.variantId == variantId);
    if (index >= 0) {
      _cartItems[index].quantity += 1;
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
    required Function(String transactionId, String invoice) onSuccess,
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
      await Future.delayed(const Duration(seconds: 1)); 
      
      final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

      _isProcessing = false;
      notifyListeners();

      onSuccess(transactionId, invoiceNumber);
      clearCart();

      return transactionId;
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

  CartItem({
    required this.id,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.unitPrice,
    required this.quantity,
    this.cartonId,
    required this.profitMargin,
  });

  double get subtotal => unitPrice * quantity;
}
