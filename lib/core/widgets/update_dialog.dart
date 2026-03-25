import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final String version;
  final String url;
  final String? releaseNotes;
  final bool isCritical;

  const UpdateDialog({
    super.key,
    required this.version,
    required this.url,
    this.releaseNotes,
    this.isCritical = false,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double _progress = 0;
  bool _isDownloading = false;
  String? _error;

  void _startDownload() async {
    setState(() {
      _isDownloading = true;
      _error = null;
    });

    try {
      await UpdateService.instance.downloadAndInstall(widget.url, (progress) {
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
      title: Text("New Update Available: ${widget.version}"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.releaseNotes != null) ...[
              const Text("What's New:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(widget.releaseNotes!),
              const SizedBox(height: 16),
            ],
            if (_isDownloading) ...[
              const Text("Downloading update..."),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 4),
              Text("${(_progress * 100).toStringAsFixed(1)}%"),
            ] else if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ] else ...[
              const Text("A new version is ready to install. Click 'Update Now' to proceed."),
            ],
          ],
        ),
      ),
      actions: [
        if (!widget.isCritical && !_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Later"),
          ),
        ElevatedButton(
          onPressed: _isDownloading ? null : _startDownload,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(_isDownloading ? "Downloading..." : "Update Now"),
        ),
      ],
    );
  }
}
