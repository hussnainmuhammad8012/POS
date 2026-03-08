import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/inventory/data/repositories/product_repository.dart';
import '../repositories/transaction_repository.dart';
import '../../features/settings/application/settings_provider.dart';

class FCMService {
  final ProductRepository productRepository;
  final TransactionRepository transactionRepository;
  final SettingsProvider settingsProvider;

  FCMService({
    required this.productRepository,
    required this.transactionRepository,
    required this.settingsProvider,
  });

  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';
  // Note: Server key should ideally be stored securely or passed from settings
  static const String _serverKey = 'YOUR_FCM_SERVER_KEY_HERE';

  /// Send daily summary to the paired admin device
  Future<void> sendDailySummary() async {
    final token = settingsProvider.adminFcmToken;
    if (token == null || token.isEmpty) return;

    final summary = await _generateDailySummary();
    
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
    final report = await _generateDailySummary(); // reuse daily logic for now
    
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
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    
    // This is a simplified summary based on existing logic
    // In a real scenario, we'd query the transaction repo for today's totals
    return {
      'date': today,
      'totalSales': 12500.0, // Placeholder
      'itemCount': 42,       // Placeholder
      'cash': 8000.0,        // Placeholder
      'credit': 4500.0,      // Placeholder
    };
  }

  Future<void> _sendToDevice({
    required String token,
    required String type,
    required Map<String, dynamic> data,
    required Map<String, String> notification,
  }) async {
    if (_serverKey == 'YOUR_FCM_SERVER_KEY_HERE') {
      print('FCM: Server Key not configured. Skipping push.');
      return;
    }

    final payload = {
      'to': token,
      'priority': 'high',
      'notification': notification,
      'data': {
        ...data,
        'type': type,
        'sent_at': DateTime.now().toIso8601String(),
      },
    };

    try {
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('FCM: Push sent successfully to $token');
      } else {
        print('FCM: Failed to send push. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('FCM: Error sending push: $e');
    }
  }
}
