// lib/features/settings/application/settings_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsProvider(this._prefs);

  // Store Information
  String get storeName => _prefs.getString('store_name') ?? 'Utility POS Central';
  String get storeAddress => _prefs.getString('store_address') ?? '123 Main Street';
  String get storePhone => _prefs.getString('store_phone') ?? '+92 300 1234567';
  double get taxRate => _prefs.getDouble('tax_rate') ?? 18.0;

  // Receipt Options
  String get receiptCustomMessage => _prefs.getString('receipt_custom_message') ?? 'Thank you for shopping with us!';

  // Payment Methods
  List<String> get paymentMethods {
    final List<String>? methods = _prefs.getStringList('payment_methods');
    if (methods == null || methods.isEmpty) {
      return ['CASH', 'JAZZCASH', 'BANK'];
    }
    return methods;
  }

  // Setters
  Future<void> updateStoreInfo({
    String? name,
    String? address,
    String? phone,
    double? tax,
  }) async {
    if (name != null) await _prefs.setString('store_name', name);
    if (address != null) await _prefs.setString('store_address', address);
    if (phone != null) await _prefs.setString('store_phone', phone);
    if (tax != null) await _prefs.setDouble('tax_rate', tax);
    notifyListeners();
  }

  Future<void> updateReceiptMessage(String message) async {
    await _prefs.setString('receipt_custom_message', message);
    notifyListeners();
  }

  Future<void> addPaymentMethod(String method) async {
    final methods = List<String>.from(paymentMethods);
    final upperMethod = method.toUpperCase();
    if (!methods.contains(upperMethod)) {
      methods.add(upperMethod);
      await _prefs.setStringList('payment_methods', methods);
      notifyListeners();
    }
  }

  Future<void> removePaymentMethod(String method) async {
    final methods = List<String>.from(paymentMethods);
    final upperMethod = method.toUpperCase();
    // Prevent removing core methods if preferred, or allow all. 
    // Usually wise to keep CASH.
    if (upperMethod != 'CASH') {
      methods.remove(upperMethod);
      await _prefs.setStringList('payment_methods', methods);
      notifyListeners();
    }
  }

  Future<void> resetToDefaults() async {
    await _prefs.clear();
    notifyListeners();
  }
}
