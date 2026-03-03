import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/entities.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.sellingPrice * quantity;
}

class PosProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};
  String _currentBarcode = '';
  int _bulkQuantity = 1;
  Customer? _selectedCustomer;

  String get currentBarcode => _currentBarcode;
  int get bulkQuantity => _bulkQuantity;
  Customer? get selectedCustomer => _selectedCustomer;

  List<CartItem> get cartItems => _items.values.toList();

  double get total =>
      _items.values.fold(0, (sum, item) => sum + item.subtotal);

  void setBarcode(String value) {
    _currentBarcode = value;
    notifyListeners();
  }

  void setBulkQuantity(int value) {
    _bulkQuantity = value.clamp(1, 9999);
    notifyListeners();
  }

  void setCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  /// Adds a product to the cart. In a full implementation this would look up
  /// the product from a repository by barcode; here we accept an instance so
  /// the UI can wire it to data access.
  void addProduct(Product product) {
    final qtyToAdd = _bulkQuantity;
    _bulkQuantity = 1;
    _currentBarcode = '';

    if (product.id == null) return;
    final existing = _items[product.id!];
    if (existing != null) {
      existing.quantity += qtyToAdd;
    } else {
      _items[product.id!] = CartItem(product: product, quantity: qtyToAdd);
    }
    notifyListeners();
  }

  void incrementQuantity(Product product) {
    if (product.id == null) return;
    final existing = _items[product.id!];
    if (existing != null) {
      existing.quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(Product product) {
    if (product.id == null) return;
    final existing = _items[product.id!];
    if (existing != null) {
      if (existing.quantity > 1) {
        existing.quantity--;
      } else {
        _items.remove(product.id!);
      }
      notifyListeners();
    }
  }

  void removeProduct(Product product) {
    if (product.id == null) return;
    _items.remove(product.id!);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedCustomer = null;
    _currentBarcode = '';
    _bulkQuantity = 1;
    notifyListeners();
  }

  String generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${DateFormat('yyyyMMdd-HHmmss').format(now)}';
  }
}

