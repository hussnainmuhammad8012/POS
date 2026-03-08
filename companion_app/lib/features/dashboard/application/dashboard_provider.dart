import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DashboardData {
  final double todaySales;
  final double activeCredits;
  final Map<String, dynamic>? yesterdayReport;

  DashboardData({
    required this.todaySales,
    required this.activeCredits,
    this.yesterdayReport,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      todaySales: (json['today_sales'] as num?)?.toDouble() ?? 0.0,
      activeCredits: (json['active_credits'] as num?)?.toDouble() ?? 0.0,
      yesterdayReport: json['yesterday_report'],
    );
  }
}

class DashboardProvider extends ChangeNotifier {
  final String serverIp;
  final String accessToken;

  DashboardData? _data;
  bool _isLoading = false;
  String? _error;

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DashboardProvider({required this.serverIp, required this.accessToken}) {
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('http://$serverIp/analytics/summary'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        _data = DashboardData.fromJson(jsonData);
      } else {
        _error = 'Failed to load dashboard: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
