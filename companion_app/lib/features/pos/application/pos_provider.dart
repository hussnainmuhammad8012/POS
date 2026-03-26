import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../inventory/data/models/product_unit_model.dart';
import '../../auth/application/auth_provider.dart';

class CartItem {
  final String id;
  final String productId; // Added for robust ID matching
  final String variantId;
  final String? baseVariantId;
  final String productName;
  final String productSku;
  final String variantName;
  double unitPrice;
  int quantity;
  double unitDiscount;
  double unitDiscountPercent;
  double taxRate;
  final List<ProductUnit> productUnits;
  String? unitId;
  String? unitName;
  int conversionRate;

  CartItem({
    required this.id,
    required this.productId,
    required this.variantId,
    this.baseVariantId,
    required this.productName,
    required this.productSku,
    required this.variantName,
    required this.unitPrice,
    required this.quantity,
    this.unitDiscount = 0,
    this.unitDiscountPercent = 0,
    this.taxRate = 0,
    this.productUnits = const [],
    this.unitId,
    this.unitName,
    this.conversionRate = 1,
  });

  double get subtotal => (unitPrice - unitDiscount) * quantity;
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;
  double get totalDiscount => unitDiscount * quantity;

  CartItem copyWith({
    String? id,
    String? productId,
    String? variantId,
    String? variantName,
    double? unitPrice,
    int? quantity,
    double? unitDiscount,
    double? unitDiscountPercent,
    double? taxRate,
    String? unitId,
    String? unitName,
    int? conversionRate,
    String? baseVariantId,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      baseVariantId: baseVariantId ?? this.baseVariantId,
      productName: productName,
      productSku: productSku,
      variantName: variantName ?? this.variantName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      unitDiscount: unitDiscount ?? this.unitDiscount,
      unitDiscountPercent: unitDiscountPercent ?? this.unitDiscountPercent,
      taxRate: taxRate ?? this.taxRate,
      productUnits: productUnits,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      conversionRate: conversionRate ?? this.conversionRate,
    );
  }
}

class PosProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final String serverIp;
  final String accessToken;
  final String deviceId;
  
  PosProvider({
    required this.authProvider,
    required this.serverIp,
    required this.accessToken,
  }) : deviceId = authProvider.serverIp ?? 'mob_dev_${DateTime.now().millisecondsSinceEpoch}' {
    _initialize();
  }

  List<CartItem> _cartItems = [];
  bool _isWholesale = false;
  bool _isLoading = false;
  String? _error;
  int _bulkQuantity = 1;

  dynamic _selectedCustomer;
  String _paymentMethod = 'CASH';
  double _billDiscount = 0;
  List<dynamic> _customers = [];
  List<String> _paymentMethodsList = ['CASH', 'JAZZCASH', 'BANK'];

  // POS Metadata from Server
  bool _allowDiscounts = true;
  bool _calculatePercentageDiscount = false;
  bool _treatUomPriceGapAsDiscount = false;
  bool _prorateUomRemainders = false;
  bool _enableTax = false;
  bool _taxInclusive = false;
  double _serverTaxRate = 0.0;
  bool _enableUomSystem = true;
  String _storeName = 'Utility Store';
  String _storeAddress = '';
  String _storePhone = '';
  String _receiptCustomMessage = 'Thank you for shopping!';

  // Polling for settings/config updates
  Timer? _pollTimer;
  int _lastKnownVersion = -1;

  Future<void> _initialize() async {
    await fetchCustomers();
    await fetchPosConfig();
    await fetchPaymentMethods();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _checkVersion();
    });
  }

  Future<void> _checkVersion() async {
    try {
      final res = await http.get(
        Uri.parse('http://$serverIp/sync/version'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 2));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final version = data['version'] as int? ?? 0;
        if (version != _lastKnownVersion && _lastKnownVersion != -1) {
          debugPrint('POS: Sync detected! Refreshing config...');
          await fetchPosConfig();
        }
        _lastKnownVersion = version;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  List<CartItem> get cartItems => _cartItems;
  bool get isWholesale => _isWholesale;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get bulkQuantity => _bulkQuantity;
  dynamic get selectedCustomer => _selectedCustomer;
  String get paymentMethod => _paymentMethod;
  double get billDiscount => _billDiscount;
  List<dynamic> get customers => _customers;
  List<String> get paymentMethodsList => _paymentMethodsList;

  bool get allowDiscounts => _allowDiscounts;
  bool get calculatePercentageDiscount => _calculatePercentageDiscount;
  bool get enableTax => _enableTax;
  bool get taxInclusive => _taxInclusive;
  double get serverTaxRate => _serverTaxRate;
  bool get enableUomSystem => _enableUomSystem;
  String get storeName => _storeName;
  String get storeAddress => _storeAddress;
  String get storePhone => _storePhone;
  String get receiptCustomMessage => _receiptCustomMessage;

  double get subtotal => _cartItems.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity));
  double get totalTax => _cartItems.fold(0, (sum, item) => sum + item.taxAmount);
  double get totalDiscount => _cartItems.fold(0.0, (sum, item) => sum + item.totalDiscount) + _billDiscount;
  double get total => subtotal + totalTax - totalDiscount;

  void setCustomer(dynamic customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  Future<void> fetchPosConfig() async {
    try {
      final response = await http.get(
        Uri.parse('http://$serverIp/settings/pos-config'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        final config = jsonDecode(response.body);
        _allowDiscounts = config['allowDiscounts'] ?? true;
        _calculatePercentageDiscount = config['calculatePercentageDiscount'] ?? false;
        _treatUomPriceGapAsDiscount = config['treatUomPriceGapAsDiscount'] ?? false;
        _prorateUomRemainders = config['prorateUomRemainders'] ?? false;
        _enableTax = config['enableTax'] ?? false;
        _taxInclusive = config['taxInclusive'] ?? false;
        _serverTaxRate = (config['taxRate'] as num?)?.toDouble() ?? 0.0;
        _enableUomSystem = config['enableUomSystem'] ?? true;
        _storeName = config['storeName'] ?? 'Utility Store';
        _storeAddress = config['storeAddress'] ?? '';
        _storePhone = config['storePhone'] ?? '';
        _receiptCustomMessage = config['receiptCustomMessage'] ?? 'Thank you for shopping!';
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching pos config: $e');
    }
  }

  Future<void> fetchCustomers() async {
    try {
      final response = await http.get(
        Uri.parse('http://$serverIp/inventory/customers'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        _customers = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching customers: $e');
    }
  }

  Future<void> fetchPaymentMethods() async {
    try {
      final response = await http.get(
        Uri.parse('http://$serverIp/settings/payment-methods'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        _paymentMethodsList = List<String>.from(jsonDecode(response.body));
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching payment methods: $e');
    }
  }

  void setBulkQuantity(int qty) {
    _bulkQuantity = qty;
    notifyListeners();
  }

  void toggleWholesale(bool value) {
    _isWholesale = value;
    notifyListeners();
  }

  void setBillDiscount(double amount) {
    if (_calculatePercentageDiscount) {
       _billDiscount = subtotal * (amount / 100);
    } else {
       _billDiscount = amount;
    }
    notifyListeners();
  }

  void setItemDiscount(String id, double value) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      double absoluteDiscount = value;
      if (_calculatePercentageDiscount) {
        absoluteDiscount = _cartItems[index].unitPrice * (value / 100);
      }
      _cartItems[index] = _cartItems[index].copyWith(unitDiscount: absoluteDiscount);
      notifyListeners();
    }
  }

  Future<void> printReceipt(Map<String, dynamic> receiptData) async {
    try {
      await http.post(
        Uri.parse('http://$serverIp/pos/print'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(receiptData),
      );
    } catch (e) {
      print('Print Error: $e');
    }
  }

  Future<String> addToCartByBarcode(String barcode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Smart Detection: Is this a Server Sync QR?
    if (barcode.contains('"session_key"') || barcode.contains('"ip"')) {
      final success = await authProvider.pairWithServer(barcode);
      _isLoading = false;
      if (success) {
        notifyListeners();
        return 'RE_SYNCED';
      }
      return 'INVALID_SYNC_QR';
    }

    try {
      final response = await http.get(
        Uri.parse('http://$serverIp/pos/product-lookup/$barcode'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _addItemFromLookup(data);
        _isLoading = false;
        notifyListeners();
        return 'SUCCESS';
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _error = 'AUTH_ERROR';
        _isLoading = false;
        notifyListeners();
        return 'AUTH_ERROR';
      } else {
        _error = 'Product not found';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return 'ERROR';
  }

  // Product Name Search --------------------------------------------------------
  List<Map<String, dynamic>> _searchSuggestions = [];
  List<Map<String, dynamic>> get searchSuggestions => _searchSuggestions;

  Future<void> searchProductsByName(String query) async {
    if (query.isEmpty) {
      _searchSuggestions = [];
      notifyListeners();
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('http://$serverIp/inventory/products/search?q=${Uri.encodeComponent(query)}&limit=8'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        _searchSuggestions = list.cast<Map<String, dynamic>>();
        notifyListeners();
      }
    } catch (_) {
      _searchSuggestions = [];
    }
  }

  Future<String> addToCartByVariantId(String variantId) async {
    return addToCartByBarcode(variantId);
  }

  void clearSearchSuggestions() {
    _searchSuggestions = [];
    notifyListeners();
  }

  Future<void> _addItemFromLookup(Map<String, dynamic> data) async {
    final type = data['type'];
    final productId = data['productId'] ?? ''; // Extract product ID
    final productName = data['productName'];
    final productSku = data['productSku'];
    
    if (type == 'unit') {
      if (!_enableUomSystem) {
        // UOM disabled: Force lookup as the base variant instead of the unit
        final barcode = data['unit']['barcode'] ?? '';
        await addToCartByBarcode(barcode); // Fixed: await and return
        return;
      }
      final unit = ProductUnit.fromJson(data['unit']);
      final unitsData = data['units'] as List? ?? [];
      final units = unitsData.map((u) => ProductUnit.fromJson(u)).toList();
      final variantId = '${productId}__${unit.id}';
      final baseVariantId = unit.baseVariantId ?? unit.id;

      await _syncReservation(baseVariantId!, _bulkQuantity * unit.conversionRate);

      _addOrUpdateItem(
        productId: productId,
        variantId: variantId,
        baseVariantId: baseVariantId,
        productName: productName,
        productSku: productSku,
        variantName: unit.unitName,
        unitPrice: _isWholesale ? (unit.wholesalePrice ?? unit.retailPrice) : unit.retailPrice,
        productUnits: units,
        unitId: unit.id,
        unitName: unit.unitName,
        conversionRate: unit.conversionRate,
      );
    } else {
      final variant = data['variant'];
      final unitsData = data['units'] as List? ?? [];
      final units = unitsData.map((u) => ProductUnit.fromJson(u)).toList();
      
      await _syncReservation(variant['id'], _bulkQuantity);

      _addOrUpdateItem(
        productId: productId,
        variantId: variant['id'],
        baseVariantId: variant['id'],
        productName: productName,
        productSku: productSku,
        variantName: variant['variant_name'] ?? '',
        unitPrice: _isWholesale ? (variant['wholesale_price'] ?? variant['retail_price']).toDouble() : variant['retail_price'].toDouble(),
        productUnits: units,
        unitId: variant['id'],
        unitName: variant['variant_name'] ?? 'Piece',
        conversionRate: 1,
      );
    }
  }

  void _addOrUpdateItem({
    required String productId,
    required String variantId,
    String? baseVariantId,
    required String productName,
    required String productSku,
    required String variantName,
    required double unitPrice,
    List<ProductUnit> productUnits = const [],
    String? unitId,
    String? unitName,
    int conversionRate = 1,
  }) {
    final index = _cartItems.indexWhere((item) => item.variantId == variantId);
    if (index >= 0) {
      _cartItems[index].quantity += _bulkQuantity;
      _autoUpscale(index);
    } else {
      _cartItems.add(CartItem(
        id: 'mob_${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        variantId: variantId,
        baseVariantId: baseVariantId,
        productName: productName,
        productSku: productSku,
        variantName: variantName,
        unitPrice: unitPrice,
        quantity: _bulkQuantity,
        taxRate: _enableTax && !_taxInclusive ? _serverTaxRate : 0.0,
        productUnits: productUnits,
        unitId: unitId,
        unitName: unitName,
        conversionRate: conversionRate,
      ));
      _autoUpscale(_cartItems.length - 1);
    }
  }


  Future<void> updateQuantity(String itemId, int delta) async {
    final index = _cartItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final item = _cartItems[index];
      final baseVariantId = item.baseVariantId ?? item.variantId;
      final stockDelta = delta * item.conversionRate;

      if (delta > 0) {
        await _syncReservation(baseVariantId, stockDelta);
      } else {
        await _releaseReservation(baseVariantId, stockDelta.abs());
      }

      _cartItems[index].quantity += delta;
      if (_cartItems[index].quantity <= 0) {
        // Downscale Logic: 1 Pet -> 5 Pieces (if conversion is 6)
        if (delta < 0 && item.conversionRate > 1 && item.productUnits.isNotEmpty) {
          final baseUnit = item.productUnits.firstWhere((u) => u.conversionRate == 1, orElse: () => item.productUnits.first);
          if (baseUnit.conversionRate == 1) { // ensure it actually is the real base unit
            final downscaledId = '${item.productId}__${baseUnit.id}';
            final piecesToRestore = item.conversionRate - 1; // Since we decremented by 1 bulk unit
            
            final existingPieceIdx = _cartItems.indexWhere((it) => it.variantId == downscaledId);
            if (existingPieceIdx >= 0) {
              _cartItems[existingPieceIdx].quantity += piecesToRestore;
              _autoUpscale(existingPieceIdx);
            } else {
              final double unitPrice = _isWholesale ? (baseUnit.wholesalePrice ?? baseUnit.retailPrice) : baseUnit.retailPrice;
              _cartItems.add(item.copyWith(
                id: 'mob_downscale_${DateTime.now().microsecondsSinceEpoch}',
                variantId: downscaledId,
                unitId: baseUnit.id,
                unitName: baseUnit.unitName,
                conversionRate: 1,
                quantity: piecesToRestore,
                unitPrice: unitPrice,
                unitDiscount: 0,
                variantName: baseUnit.unitName,
              ));
            }
          }
        }
        _cartItems.removeAt(index);
      } else {
        _autoUpscale(index);
      }
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String id) async {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final item = _cartItems[index];
      await _releaseReservation(item.baseVariantId ?? item.variantId, item.quantity * item.conversionRate);
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  void _autoUpscale(int index) {
    if (index < 0 || index >= _cartItems.length) return;
    if (!_enableUomSystem) return; // Respect global toggle
    var item = _cartItems[index];
    print('MOBILE UPSCALE: Checking ${item.productName} (qty: ${item.quantity}, conv: ${item.conversionRate})');
    
    if (item.productUnits.isEmpty) {
      print('MOBILE UPSCALE: SKIPPED (No product units found for ${item.productName})');
      return;
    }

    // Only upscale from base unit (conversionRate 1) to avoid confusing users
    if (item.conversionRate != 1) {
      print('MOBILE UPSCALE: SKIPPED (Already a bulk unit: ${item.unitName})');
      return;
    }

    // Find the highest unit that divides the current quantity
    final sortedUnits = List<ProductUnit>.from(item.productUnits)
      ..sort((a, b) => b.conversionRate.compareTo(a.conversionRate));

    for (final unit in sortedUnits) {
      print('MOBILE UPSCALE: Evaluating unit ${unit.unitName} (threshold: ${unit.conversionRate})');
      if (unit.conversionRate > 1 && item.quantity >= unit.conversionRate) {
        print('MOBILE UPSCALE: TRIGGERED for ${unit.unitName}!');
        // We can upscale (e.g., 8 pieces -> 1 Pet + 2 Pieces remaining)
        final wholeUnits = item.quantity ~/ unit.conversionRate;
        final remainder = item.quantity % unit.conversionRate;

        if (wholeUnits > 0) {
          double unitPrice = _isWholesale 
              ? (unit.wholesalePrice ?? unit.retailPrice) 
              : unit.retailPrice;

          final upscaledId = '${item.productId}__${unit.id}'; // Use consistent productId__unitId format
          final existingUnitIdx = _cartItems.indexWhere((it) => it.variantId == upscaledId);

          if (existingUnitIdx >= 0 && existingUnitIdx != index) {
            // Merge into existing bulk row
            _cartItems[existingUnitIdx].quantity += wholeUnits;
            _cartItems[index].quantity = remainder;
            // Recursively check the existing row for further upscaling if needed
            _autoUpscale(existingUnitIdx);
          } else {
            // Transform current row or add new bulk row
            double unitDiscount = 0;
            double finalUnitPrice = unitPrice;

            if (_treatUomPriceGapAsDiscount) {
              final baseUnit = item.productUnits.firstWhere((u) => u.conversionRate == 1, orElse: () => item.productUnits.first);
              final basePrice = (_isWholesale) ? (baseUnit.wholesalePrice ?? baseUnit.retailPrice) : baseUnit.retailPrice;
              final expectedBulkPrice = basePrice * unit.conversionRate;
              if (expectedBulkPrice > unitPrice) {
                unitDiscount = expectedBulkPrice - unitPrice;
                finalUnitPrice = expectedBulkPrice;
              }
            }

            if (remainder == 0) {
              // Exact match, transform this row
              _cartItems[index] = item.copyWith(
                variantId: upscaledId,
                unitId: unit.id,
                unitName: unit.unitName,
                conversionRate: unit.conversionRate,
                quantity: wholeUnits,
                unitPrice: finalUnitPrice,
                unitDiscount: unitDiscount,
                variantName: unit.unitName,
              );
            } else {
              // Mixed quantities: e.g., 8 pieces becomes 1 Pet + 2 pieces
              _cartItems.add(item.copyWith(
                id: 'mob_bulk_${DateTime.now().microsecondsSinceEpoch}',
                variantId: upscaledId,
                unitId: unit.id,
                unitName: unit.unitName,
                conversionRate: unit.conversionRate,
                quantity: wholeUnits,
                unitPrice: finalUnitPrice,
                unitDiscount: unitDiscount,
                variantName: unit.unitName,
              ));
              _cartItems[index].quantity = remainder;
            }
          }
          
          if (_cartItems[index].quantity <= 0) {
            _cartItems.removeAt(index);
          }
          break; // Process one upscale at a time; others will be handled via recursion or next trigger
        }
      }
    }
  }

  void changeItemUnit(String itemId, ProductUnit newUnit) {
    final index = _cartItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final item = _cartItems[index];
      
      double unitPrice = (_isWholesale && newUnit.conversionRate == 1) 
          ? (newUnit.wholesalePrice ?? newUnit.retailPrice) 
          : newUnit.retailPrice;

      double unitDiscount = 0;
      if (_treatUomPriceGapAsDiscount && newUnit.conversionRate > 1) {
        final baseUnit = item.productUnits.firstWhere((u) => u.conversionRate == 1, orElse: () => item.productUnits.first);
        final basePrice = (_isWholesale) 
            ? (baseUnit.wholesalePrice ?? baseUnit.retailPrice) 
            : baseUnit.retailPrice;
        final expectedBulkPrice = basePrice * newUnit.conversionRate;
        if (expectedBulkPrice > unitPrice) {
          unitDiscount = expectedBulkPrice - unitPrice;
          unitPrice = expectedBulkPrice;
        }
      }

      _cartItems[index] = item.copyWith(
        unitId: newUnit.id,
        unitName: newUnit.unitName,
        conversionRate: newUnit.conversionRate,
        unitPrice: unitPrice,
        unitDiscount: unitDiscount,
      );
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    try {
      await http.post(
        Uri.parse('http://$serverIp/pos/cart/clear'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({'deviceId': deviceId}),
      );
    } catch (e) {
      print('Error clearing cart reservation: $e');
    }

    _cartItems.clear();
    _billDiscount = 0;
    _selectedCustomer = null;
    notifyListeners();
  }

  Future<void> _syncReservation(String variantId, int qty) async {
    try {
      await http.post(
        Uri.parse('http://$serverIp/pos/cart/reserve'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({'variantId': variantId, 'quantity': qty, 'deviceId': deviceId}),
      );
    } catch (e) {
      print('Sync Error: $e');
    }
  }

  Future<void> _releaseReservation(String variantId, int qty) async {
    try {
      await http.post(
        Uri.parse('http://$serverIp/pos/cart/release'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({'variantId': variantId, 'quantity': qty, 'deviceId': deviceId}),
      );
    } catch (e) {
      print('Release Error: $e');
    }
  }

  Future<Map<String, dynamic>?> checkout({
    double? cashPaid,
    double? creditAmount,
    DateTime? dueDate,
    String? paymentMethod,
  }) async {
    if (_cartItems.isEmpty) return null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('http://$serverIp/pos/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'items': _cartItems.map((i) => {
            'productId': i.productId, // Essential for server-side variant resolution
            'variantId': i.baseVariantId ?? i.variantId,
            'quantity': i.quantity * i.conversionRate,
            'unitPrice': i.unitPrice / i.conversionRate,
            'discount': i.totalDiscount,
            'unitId': i.unitId,
            'unitName': i.unitName,
            'total': i.total,
            'productName': i.productName,
          }).toList(),
          'subtotal': subtotal,
          'discount': totalDiscount,
          'total': total,
          'paymentMethod': paymentMethod ?? _paymentMethod,
          'customerId': _selectedCustomer?['id'],
          'customer': _selectedCustomer,
          'deviceId': deviceId,
          'cashPaid': cashPaid ?? total,
          'creditAmount': creditAmount ?? 0.0,
          'dueDate': dueDate?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final serverResult = jsonDecode(response.body);
        
        // Enrich result with cart information for PDF receipt
        final receiptData = {
          'invoice': serverResult['invoice'],
          'date': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
          'storeName': _storeName,
          'storeAddress': _storeAddress,
          'storePhone': _storePhone,
          'receiptCustomMessage': _receiptCustomMessage,
          'customer': _selectedCustomer,
          'items': _cartItems.map((i) => {
            'productName': i.productName,
            'variantName': i.variantName,
            'unitName': i.unitName,
            'quantity': i.quantity,
            'unitPrice': i.unitPrice,
            'unitDiscount': i.unitDiscount,
            'unitDiscountPercent': i.unitDiscountPercent,
            'taxRate': i.taxRate,
            'taxAmount': i.taxAmount,
            'total': i.total,
          }).toList(),
          'subtotal': subtotal,
          'discount': totalDiscount,
          'discountPercent': subtotal > 0 ? (totalDiscount / subtotal * 100) : 0.0,
          'tax': totalTax,
          'taxInclusive': _taxInclusive,
          'total': total,
          'cashPaid': cashPaid ?? total,
          'creditAmount': creditAmount ?? 0.0,
          'paymentMethod': paymentMethod ?? _paymentMethod,
        };

        _cartItems.clear(); // Clear local list
        _selectedCustomer = null;
        _isLoading = false;
        notifyListeners();
        return receiptData;
      }
    } catch (e) {
      _error = 'Checkout failed';
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }
}
