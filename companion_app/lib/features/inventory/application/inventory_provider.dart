import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:companion_app/features/inventory/data/models/product_model.dart';
import 'package:companion_app/features/inventory/data/models/category_model.dart';
import 'package:companion_app/features/inventory/data/models/supplier_model.dart';
import 'package:companion_app/features/inventory/data/models/product_unit_model.dart';

class InventoryProvider extends ChangeNotifier {
  final String serverIp;
  final String accessToken;

  List<Product> _products = [];
  List<Category> _categories = [];
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  bool _isUomEnabled = true;
  bool _isTaxEnabled = false;
  double _defaultTaxRate = 0.0;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  bool get isUomEnabled => _isUomEnabled;
  bool get isTaxEnabled => _isTaxEnabled;
  double get defaultTaxRate => _defaultTaxRate;

  InventoryProvider({required this.serverIp, required this.accessToken}) {
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final baseUrl = 'http://$serverIp/inventory';
      final headers = {'Authorization': 'Bearer $accessToken'};

      // Fetch UOM Toggle status from Ping
      final pingRes = await http.get(Uri.parse('http://$serverIp/ping'), headers: headers);
      if (pingRes.statusCode == 200) {
        final pingData = jsonDecode(pingRes.body);
        _isUomEnabled = pingData['isUomEnabled'] ?? false;
        _isTaxEnabled = pingData['isTaxEnabled'] ?? false;
        _defaultTaxRate = (pingData['taxRate'] as num?)?.toDouble() ?? 0.0;
      }

      final prodRes = await http.get(Uri.parse('$baseUrl/products'), headers: headers);
      final catRes = await http.get(Uri.parse('$baseUrl/categories'), headers: headers);
      final supRes = await http.get(Uri.parse('$baseUrl/suppliers'), headers: headers);

      if (prodRes.statusCode == 200 && catRes.statusCode == 200) {
        final List prodData = jsonDecode(prodRes.body);
        final List catData = jsonDecode(catRes.body);

        _products = prodData.map((j) => Product.fromJson(j)).toList();
        _categories = catData.map((j) => Category.fromJson(j)).toList();
        
        if (supRes.statusCode == 200) {
          final List supData = jsonDecode(supRes.body);
          _suppliers = supData.map((j) => Supplier.fromJson(j)).toList();
        }
        
        debugPrint('Fetched ${_products.length} products. Sample stock: ${_products.isNotEmpty ? _products.first.currentStock : "N/A"}');
      } else {
        debugPrint('Fetch failed: Prod ${prodRes.statusCode}, Cat ${catRes.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateStock(String productId, int quantityChange, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('http://$serverIp/inventory/stock-update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'product_id': productId,
          'quantity_change': quantityChange,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Stock update success for $productId');
        await fetchInventory(); // Force refresh local list
        return true;
      } else {
        debugPrint('Stock update failed: ${response.statusCode} - ${response.body}');
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
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
        debugPrint('Carton received successfully');
        await fetchInventory();
        return true;
      } else {
        debugPrint('Receive carton failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Receive carton error: $e');
    }
    return false;
  }

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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
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
        debugPrint('Product created successfully');
        await fetchInventory(); // Refresh list immediately
        return null;
      } else {
        final body = jsonDecode(response.body);
        final errorMessage = body['message'] ?? body['error'] ?? 'Unknown error occurred';
        debugPrint('Add product failed: ${response.statusCode} - $errorMessage');
        return errorMessage;
      }
    } catch (e) {
      debugPrint('Add product error: $e');
      return e.toString();
    }
  }

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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'name': name,
          'contactPerson': contactPerson,
          'phone': phone,
          'email': email,
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Supplier created successfully');
        await fetchInventory(); // Refresh list immediately
        return true;
      } else {
        debugPrint('Add supplier failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Add supplier error: $e');
    }
    return false;
  }
}
