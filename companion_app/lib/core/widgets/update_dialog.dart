import 'package:flutter/material.dart';
import '../services/update_service.dart';

class MobileUpdateDialog extends StatefulWidget {
  final String version;
  final String url;
  final String? releaseNotes;
  final bool isCritical;

  const MobileUpdateDialog({
    super.key,
    required this.version,
    required this.url,
    this.releaseNotes,
    this.isCritical = false,
  });

  @override
  State<MobileUpdateDialog> createState() => _MobileUpdateDialogState();
}

class _MobileUpdateDialogState extends State<MobileUpdateDialog> {
  double _progress = 0;
  bool _isDownloading = false;
  String? _error;

  void _startDownload() async {
    setState(() {
      _isDownloading = true;
      _error = null;
    });

    try {
      await UpdateService.instance.downloadAndOpen(widget.url, (progress) {
        setState(() {
          _progress = progress;
        });
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _error = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("New Update: ${widget.version}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.releaseNotes != null) ...[
            const Text("Release Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.releaseNotes!),
            const SizedBox(height: 16),
          ],
          if (_isDownloading) ...[
            const Text("Downloading APK..."),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 4),
            Text("${(_progress * 100).toStringAsFixed(1)}%"),
          ] else if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ] else ...[
            const Text("A new version is available. Would you like to update?"),
          ],
        ],
      ),
      actions: [
        if (!widget.isCritical && !_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Later"),
          ),
        ElevatedButton(
          onPressed: _isDownloading ? null : _startDownload,
          child: Text(_isDownloading ? "Downloading..." : "Update Now"),
        ),
      ],
    );
  }
}
