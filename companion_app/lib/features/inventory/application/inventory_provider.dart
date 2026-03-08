import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/models/product_model.dart';
import '../data/models/category_model.dart';

class InventoryProvider extends ChangeNotifier {
  final String serverIp;
  final String accessToken;

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  InventoryProvider({required this.serverIp, required this.accessToken}) {
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final baseUrl = 'http://$serverIp/inventory';
      final headers = {'Authorization': 'Bearer $accessToken'};

      final prodRes = await http.get(Uri.parse('$baseUrl/products'), headers: headers);
      final catRes = await http.get(Uri.parse('$baseUrl/categories'), headers: headers);

      if (prodRes.statusCode == 200 && catRes.statusCode == 200) {
        final List prodData = jsonDecode(prodRes.body);
        final List catData = jsonDecode(catRes.body);

        _products = prodData.map((j) => Product.fromJson(j)).toList();
        _categories = catData.map((j) => Category.fromJson(j)).toList();
      } else if (prodRes.statusCode == 401 || prodRes.statusCode == 403) {
        debugPrint('Session invalid during fetch');
        // This will be handled by the UI or AuthProvider if we were listening
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
        await fetchInventory(); // Refresh
        return true;
      }
    } catch (e) {
      debugPrint('Stock update error: $e');
    }
    return false;
  }
}
