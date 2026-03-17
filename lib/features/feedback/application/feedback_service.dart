import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class FeedbackService {
  static const String _baseUrl = 'http://localhost:5000/api';

  Future<bool> submitFeedback({
    required String type,
    required String content,
    List<String> filePaths = const [],
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/submit-feedback');
      final request = http.MultipartRequest('POST', uri);

      request.fields['licenseKey'] = 'RR-TRIAL-KEY-123'; // Placeholder
      request.fields['type'] = type.toLowerCase();
      request.fields['content'] = content;

      for (String path in filePaths) {
        request.files.add(await http.MultipartFile.fromPath(
          'attachments',
          path,
          filename: basename(path),
        ));
      }

      final response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      print('Feedback submission error: $e');
      return false;
    }
  }
}
