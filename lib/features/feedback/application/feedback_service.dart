import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import '../../../core/database/app_database.dart';

class FeedbackService {
  // The management website URL — this is where feedback is sent to our server
  static const String _managementBaseUrl = 'http://rairoyalscode.com/api';
  // Fallback for localhost development
  static const String _localBaseUrl = 'http://localhost:5000/api';

  /// Submits feedback to the RaiRoyals management server.
  /// Gets the license key from the local DB so it's correctly attributed.
  Future<bool> submitFeedback({
    required String type,
    required String content,
    List<String> filePaths = const [],
  }) async {
    // Try to get the real license key from local DB
    String licenseKey = 'RR-UNKNOWN';
    try {
      final db = AppDatabase.instance.db;
      final result = await db.query('settings', where: 'key = ?', whereArgs: ['license_key']);
      if (result.isNotEmpty && result.first['value'] != null) {
        licenseKey = result.first['value'] as String;
      }
    } catch (_) {}

    // Try production server first, then localhost
    for (final baseUrl in [_managementBaseUrl, _localBaseUrl]) {
      try {
        final uri = Uri.parse('$baseUrl/submit-feedback');
        final request = http.MultipartRequest('POST', uri);

        request.fields['licenseKey'] = licenseKey;
        request.fields['type'] = type.toLowerCase();
        request.fields['content'] = content;

        for (String path in filePaths) {
          request.files.add(await http.MultipartFile.fromPath(
            'attachments',
            path,
            filename: basename(path),
          ));
        }

        final response = await request.send().timeout(const Duration(seconds: 10));
        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        }
      } catch (e) {
        print('Feedback submission error ($baseUrl): $e');
        continue;
      }
    }
    return false;
  }
}
