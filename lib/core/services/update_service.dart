import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static final UpdateService instance = UpdateService._();
  UpdateService._();

  bool _isDownloading = false;
  double _downloadProgress = 0;

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  Future<void> downloadAndInstall(String url, Function(double) onProgress) async {
    if (_isDownloading) return;
    _isDownloading = true;

    try {
      final response = await http.Client().send(http.Request('GET', Uri.parse(url)));
      final contentLength = response.contentLength ?? 0;
      
      final tempDir = await getTemporaryDirectory();
      final fileName = p.basename(url);
      final filePath = p.join(tempDir.path, fileName);
      final file = File(filePath);

      int downloaded = 0;
      final List<int> bytes = [];

      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
        downloaded += chunk.length;
        if (contentLength > 0) {
          _downloadProgress = downloaded / contentLength;
          onProgress(_downloadProgress);
        }
      }

      await file.writeAsBytes(bytes);
      _isDownloading = false;

      // Launch the MSIX/Installer
      await _launchInstaller(filePath);
    } catch (e) {
      _isDownloading = false;
      rethrow;
    }
  }

  Future<void> _launchInstaller(String path) async {
    if (Platform.isWindows) {
      // For MSIX, we can just open the file. 
      // Windows will handle the sideloading/installation process.
      final Uri uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        // Exit the app so the installer can run cleanly
        exit(0);
      } else {
        // Fallback for some environments
        await Process.start('explorer.exe', [path]);
        exit(0);
      }
    }
  }
}
