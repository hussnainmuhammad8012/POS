import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:companion_app/features/inventory/data/models/product_model.dart';
import 'package:companion_app/features/inventory/data/models/category_model.dart';
import 'package:companion_app/features/inventory/data/models/supplier_model.dart';
import 'package:companion_app/features/inventory/data/models/product_unit_model.dart';
import 'package:companion_app/features/inventory/data/models/stock_movement_model.dart';

class InventoryProvider extends ChangeNotifier {
  final String serverIp;
  final String accessToken;

  List<Product> _products = [];
  List<Category> _categories = [];
  List<Supplier> _suppliers = [];
  List<CompanionStockMovement> _stockMovements = [];
  bool _isLoading = false;
  bool _isMovementsLoading = false;
  bool _isUomEnabled = true;
  bool _isTaxEnabled = false;
  double _defaultTaxRate = 0.0;

  // Print queue state
  List<Map<String, dynamic>> _printQueue = [];
  bool _isPrinting = false;

  // Polling state
  Timer? _pollTimer;
  int _lastKnownVersion = -1;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Supplier> get suppliers => _suppliers;
  List<CompanionStockMovement> get stockMovements => _stockMovements;
  bool get isLoading => _isLoading;
  bool get isMovementsLoading => _isMovementsLoading;
  bool get isUomEnabled => _isUomEnabled;
  bool get isTaxEnabled => _isTaxEnabled;
  double get defaultTaxRate => _defaultTaxRate;
  List<Map<String, dynamic>> get printQueue => _printQueue;
  bool get isPrinting => _isPrinting;

  InventoryProvider({required this.serverIp, required this.accessToken}) {
    fetchInventory();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── POLLING ──

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkVersion();
    });
  }

  void stopPolling() => _pollTimer?.cancel();

  void resumePolling() {
    _pollTimer?.cancel();
    _startPolling();
  }

  Future<void> _checkVersion() async {
    try {
      final res = await http
          .get(
            Uri.parse('http://$serverIp/sync/version'),
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 2));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final version = data['version'] as int? ?? 0;
        if (version != _lastKnownVersion) {
          _lastKnownVersion = version;
          await fetchInventory();
        }
      }
    } catch (_) {
      // Silent fail — network may be unavailable
    }
  }

  // ── FETCH ALL ──

  Future<void> fetchInventory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final baseUrl = 'http://$serverIp/inventory';
      final headers = {'Authorization': 'Bearer $accessToken'};

      final pingRes = await http
          .get(Uri.parse('http://$serverIp/ping'), headers: headers)
          .timeout(const Duration(seconds: 5));
      if (pingRes.statusCode == 200) {
        final pingData = jsonDecode(pingRes.body);
        _isUomEnabled = pingData['isUomEnabled'] ?? false;
        _isTaxEnabled = pingData['isTaxEnabled'] ?? false;
        _defaultTaxRate = (pingData['taxRate'] as num?)?.toDouble() ?? 0.0;
      }

      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/products'), headers: headers),
        http.get(Uri.parse('$baseUrl/categories'), headers: headers),
        http.get(Uri.parse('$baseUrl/suppliers'), headers: headers),
      ]).timeout(const Duration(seconds: 10));

      final prodRes = results[0];
      final catRes = results[1];
      final supRes = results[2];

      if (prodRes.statusCode == 200) {
        final List prodData = jsonDecode(prodRes.body);
        _products = prodData.map((j) => Product.fromJson(j)).toList();
      }
      if (catRes.statusCode == 200) {
        final List catData = jsonDecode(catRes.body);
        final flatCategories = catData.map((j) => Category.fromJson(j)).toList();
        
        // Build hierarchy
        final parents = flatCategories.where((c) => c.parentId == null).toList();
        _categories = parents.map((p) {
          final subs = flatCategories.where((c) => c.parentId == p.id).toList();
          return p.copyWith(subcategories: subs);
        }).toList();
      }
      if (supRes.statusCode == 200) {
        final List supData = jsonDecode(supRes.body);
        _suppliers = supData.map((j) => Supplier.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Inventory fetch error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── STOCK MOVEMENTS ──

  Future<void> fetchStockMovements({String? productId, String? type}) async {
    _isMovementsLoading = true;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (productId != null) params['productId'] = productId;
      if (type != null && type != 'ALL') params['type'] = type;
      params['limit'] = '150';

      final uri = Uri.parse('http://$serverIp/inventory/stock-movements')
          .replace(queryParameters: params);
      final res = await http
          .get(uri, headers: {'Authorization': 'Bearer $accessToken'})
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        _stockMovements = data.map((j) => CompanionStockMovement.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Stock movements fetch error: $e');
    }

    _isMovementsLoading = false;
    notifyListeners();
  }

  // ── STOCK ──

  Future<bool> updateStock(String productId, int quantityChange, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('http://$serverIp/inventory/stock-update'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({'product_id': productId, 'quantity_change': quantityChange, 'reason': reason}),
      );
      if (response.statusCode == 200) {
        await fetchInventory();
        return true;
      }
    } catch (e) {
      debugPrint('Stock update error: $e');
    }
    return false;
  }

  Future<bool> receiveCarton({
    required String productId,
    required int quantity,
    required double totalCost,
    required double paidAmount,
    String? supplierId,
    String? notes,
    DateTime? dueDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://$serverIp/inventory/receive-carton'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
          'total_cost': totalCost,
          'paid_amount': paidAmount,
          'supplier_id': supplierId,
          'notes': notes,
          'due_date': dueDate?.toIso8601String(),
        }),
      );
      if (response.statusCode == 200) {
        await fetchInventory();
        return true;
      }
    } catch (e) {
      debugPrint('Receive carton error: $e');
    }
    return false;
  }

  // ── PRODUCT CRUD ──

  Future<String?> addProduct({
    required String categoryId,
    required String name,
    required String baseSku,
    String? description,
    String? supplierId,
    String unitType = 'Pieces',
    String? barcode,
    required double costPrice,
    required double retailPrice,
    double? wholesalePrice,
    double? mrp,
    double taxRate = 0.0,
    int initialStock = 0,
    int lowStockThreshold = 10,
    String? qrCode,
    List<ProductUnit> units = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://$serverIp/inventory/products'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          'categoryId': categoryId,
          'name': name,
          'baseSku': baseSku,
          'description': description,
          'supplierId': supplierId,
          'unitType': unitType,
          'barcode': barcode,
          'qrCode': qrCode,
          'costPrice': costPrice,
          'retailPrice': retailPrice,
          'wholesalePrice': wholesalePrice,
          'mrp': mrp,
          'taxRate': taxRate,
          'initialStock': initialStock,
          'lowStockThreshold': lowStockThreshold,
          'units': units.map((u) => u.toJson()).toList(),
        }),
      );
      if (response.statusCode == 200) {
        await fetchInventory();
        return null; // null = success
      }
      final body = jsonDecode(response.body);
      return body['message'] ?? body['error'] ?? 'Unknown error';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> editProduct({
    required String productId,
    String? categoryId,
    String? name,
    String? baseSku,
    String? description,
    String? unitType,
    String? barcode,
    String? qrCode,
    double? costPrice,
    double? retailPrice,
    double? wholesalePrice,
    double? mrp,
    double? taxRate,
    int? lowStockThreshold,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('http://$serverIp/inventory/products/$productId'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          if (categoryId != null) 'categoryId': categoryId,
          if (name != null) 'name': name,
          if (baseSku != null) 'baseSku': baseSku,
          if (description != null) 'description': description,
          if (unitType != null) 'unitType': unitType,
          if (barcode != null) 'barcode': barcode,
          if (qrCode != null) 'qrCode': qrCode,
          if (costPrice != null) 'costPrice': costPrice,
          if (retailPrice != null) 'retailPrice': retailPrice,
          if (wholesalePrice != null) 'wholesalePrice': wholesalePrice,
          if (mrp != null) 'mrp': mrp,
          if (taxRate != null) 'taxRate': taxRate,
          if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
        }),
      );
      if (response.statusCode == 200) {
        await fetchInventory();
        return null;
      }
      final body = jsonDecode(response.body);
      return body['error'] ?? 'Unknown error';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteProduct(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://$serverIp/inventory/products/$productId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        await fetchInventory();
        return null;
      }
      return jsonDecode(response.body)['error'] ?? 'Delete failed';
    } catch (e) {
      return e.toString();
    }
  }

  // ── CATEGORY CRUD ──

  Future<String?> addCategory({
    required String name,
    String? parentId,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://$serverIp/inventory/categories'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({'name': name, 'parentId': parentId, 'description': description}),
      );
      if (response.statusCode == 200) {
        await fetchInventory();
        return null;
      }
      return jsonDecode(response.body)['error'] ?? 'Create failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> editCategory({
    required String categoryId,
    String? name,
    String? description,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('http://$serverIp/inventory/categories/$categoryId'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          if (name != null) 'name': name,
          if (description != null) 'description': description,
        }),
      );
      if (response.statusCode == 200) {
        await fetchInventory();
        return null;
      }
      return jsonDecode(response.body)['error'] ?? 'Update failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteCategory(String categoryId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://$serverIp/inventory/categories/$categoryId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        await fetchInventory();
        return null;
      }
      return jsonDecode(response.body)['error'] ?? 'Delete failed';
    } catch (e) {
      return e.toString();
    }
  }

  // ── SUPPLIER ──

  Future<bool> addSupplier({
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://$serverIp/inventory/suppliers'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({'name': name, 'contactPerson': contactPerson, 'phone': phone, 'email': email, 'address': address}),
      );
      if (response.statusCode == 200) {
        await fetchInventory();
        return true;
      }
    } catch (e) {
      debugPrint('Add supplier error: $e');
    }
    return false;
  }

  // ── PRINT LABEL QUEUE ──

  Future<Map<String, dynamic>?> requestPrintLabel({
    required String productId,
    required String productName,
    required String barcode,
    required String qrData,
    String? unitId,
    String? unitName,
    int copies = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://$serverIp/inventory/print-label'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          'productId': productId,
          'productName': productName,
          'barcode': barcode,
          'qrData': qrData,
          'unitId': unitId,
          'unitName': unitName,
          'copies': copies,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Print label error: $e');
    }
    return null;
  }

  Future<void> fetchPrintQueue() async {
    try {
      final res = await http.get(
        Uri.parse('http://$serverIp/inventory/print-queue'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _printQueue = List<Map<String, dynamic>>.from(data['queue'] ?? []);
        _isPrinting = data['isPrinting'] ?? false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Print queue fetch error: $e');
    }
  }
}
