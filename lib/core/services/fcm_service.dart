import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../../features/inventory/data/repositories/product_repository.dart';
import '../repositories/transaction_repository.dart';
import '../../features/analytics/data/analytics_repository.dart';
import '../../features/settings/application/settings_provider.dart';

class FCMService {
  final ProductRepository _productRepository;
  final TransactionRepository _transactionRepository;
  final AnalyticsRepository _analyticsRepository;
  final SettingsProvider _settingsProvider;

  FCMService({
    required ProductRepository productRepository,
    required TransactionRepository transactionRepository,
    required AnalyticsRepository analyticsRepository,
    required SettingsProvider settingsProvider,
  })  : _productRepository = productRepository,
        _transactionRepository = transactionRepository,
        _analyticsRepository = analyticsRepository,
        _settingsProvider = settingsProvider;

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
    'https://www.googleapis.com/auth/cloud-platform',
  ];
  
  /// Get OAuth2 access token for FCM v1
  Future<String?> _getAccessToken() async {
    try {
      final jsonString = await rootBundle.loadString('assets/fcm/service-account.json');
      Map<String, dynamic> data = json.decode(jsonString);
      
      // Ensure private key handles literal \n characters if they exist
      if (data['private_key'] != null) {
        data['private_key'] = data['private_key'].toString().replaceAll('\\n', '\n').trim();
      }

      final credentials = ServiceAccountCredentials.fromJson(data);
      final client = await clientViaServiceAccount(credentials, _scopes);
      
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      print('FCM: Error getting access token: $e');
      return null;
    }
  }

  /// Send daily summary to the paired admin device
  Future<void> sendDailySummary() async {
    final token = _settingsProvider.adminFcmToken;
    print('FCM: Attempting to send daily summary. Token present: ${token != null && token.isNotEmpty}');
    
    if (token == null || token.isEmpty) {
      print('FCM: Skipping daily summary - No Admin FCM Token configured in Settings.');
      return;
    }

    print('FCM: Generating real-time report for today...');
    final summary = await _generateDailySummary();
    print('FCM: Report generated. Total Sales: Rs. ${summary['totalSales']}');
    
    await _sendToDevice(
      token: token,
      type: 'daily_summary',
      data: summary,
      notification: {
        'title': 'Hunain Mart - Daily Summary',
        'body': 'Sales: Rs. ${summary['totalSales']}, Items: ${summary['itemCount']}',
      },
    );
  }

  /// Send on-demand report to a specific device
  Future<void> sendOnDemandReport(String token) async {
    final report = await _generateDailySummary();
    
    await _sendToDevice(
      token: token,
      type: 'on_demand_report',
      data: report,
      notification: {
        'title': 'Hunain Mart - Current Report',
        'body': 'Sales: Rs. ${report['totalSales']}',
      },
    );
  }

  Future<Map<String, dynamic>> _generateDailySummary() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final totalSales = await _analyticsRepository.getTotalRevenue(todayStart, todayEnd);
    final cashSales = totalSales - await _analyticsRepository.getTodayCreditSales();
    final creditSales = await _analyticsRepository.getTodayCreditSales();
    
    // Get transaction count
    final transactions = await _transactionRepository.getTransactionsByDateRange(todayStart, todayEnd);
    final itemCount = transactions.length;

    return {
      'date': todayStart.toIso8601String(),
      'totalSales': totalSales.toStringAsFixed(2),
      'itemCount': itemCount.toString(),
      'cash': cashSales.toStringAsFixed(2),
      'credit': creditSales.toStringAsFixed(2),
    };
  }

  Future<void> _sendToDevice({
    required String token,
    required String type,
    required Map<String, dynamic> data,
    required Map<String, String> notification,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      print('FCM: Failed to obtain OAuth2 token. Check assets/fcm/service-account.json');
      return;
    }

    // Get Project ID from asset during runtime or hardcode from verified json
    final jsonString = await rootBundle.loadString('assets/fcm/service-account.json');
    final projectId = json.decode(jsonString)['project_id'];
    final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

    final payload = {
      'message': {
        'token': token,
        'notification': notification,
        'data': {
          ...data,
          'type': type,
          'sent_at': DateTime.now().toIso8601String(),
        },
        'android': {
          'priority': 'high',
          'notification': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'channel_id': 'high_importance_channel',
          }
        }
      }
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('FCM: Push sent successfully to device.');
      } else {
        print('FCM: Failed to send push. Status: ${response.statusCode}');
        print('FCM: Error Body: ${response.body}');
      }
    } catch (e) {
      print('FCM: Error sending push: $e');
    }
  }
}
