import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/toast_notification.dart';
import '../../application/feedback_service.dart';

enum FeedbackType { positive, negative, neutral }

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _textController = TextEditingController();
  final _screenshotController = ScreenshotController();
  FeedbackType _selectedType = FeedbackType.neutral;
  List<File> _attachments = [];
  bool _isSubmitting = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _attachments.addAll(result.paths.where((p) => p != null).map((p) => File(p!)));
      });
    }
  }

  Future<void> _captureScreenshot() async {
    // This is a bit tricky since we want to capture the WHOLE app or the current screen.
    // For now, we'll just show a success message as if we captured it, 
    // or use the Screenshot controller if wrapped.
    AppToast.show(context, title: 'Feature Coming', message: 'Full app screenshot capture is being integrated.', type: ToastType.info);
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _submitFeedback() async {
    if (_textController.text.isEmpty) {
      AppToast.show(context, title: 'Input Required', message: 'Please provide some details about your feedback.', type: ToastType.warning);
      return;
    }

    setState(() => _isSubmitting = true);

    final service = FeedbackService();
    final success = await service.submitFeedback(
      type: _selectedType.toString().split('.').last,
      content: _textController.text,
      filePaths: _attachments.map((f) => f.path).toList(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      
      if (success) {
        setState(() {
          _textController.clear();
          _attachments.clear();
          _selectedType = FeedbackType.neutral;
        });
        AppToast.show(
          context,
          title: 'Feedback Sent',
          message: 'Thank you! Your feedback has been received by RaiRoyalsCode.',
          type: ToastType.success,
        );
      } else {
        AppToast.show(
          context,
          title: 'Submission Failed',
          message: 'Could not send feedback. Please check your connection.',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Share Your Feedback',
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us improve the POS system. Your feedback goes directly to our development team.',
              style: TextStyle(color: isDark ? AppColors.DARK_TEXT_SECONDARY : AppColors.LIGHT_TEXT_SECONDARY),
            ),
            const SizedBox(height: 24),

            // Body Row - use Expanded here since we're inside a Column with a bounded parent (Scaffold)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Feedback Form
                  Expanded(
                    flex: 2,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('What kind of feedback do you have?', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _TypeButton(
                                  label: 'Positive',
                                  icon: LucideIcons.smile,
                                  color: Colors.green,
                                  isSelected: _selectedType == FeedbackType.positive,
                                  onTap: () => setState(() => _selectedType = FeedbackType.positive),
                                ),
                                const SizedBox(width: 12),
                                _TypeButton(
                                  label: 'Neutral',
                                  icon: LucideIcons.meh,
                                  color: Colors.amber,
                                  isSelected: _selectedType == FeedbackType.neutral,
                                  onTap: () => setState(() => _selectedType = FeedbackType.neutral),
                                ),
                                const SizedBox(width: 12),
                                _TypeButton(
                                  label: 'Negative',
                                  icon: LucideIcons.frown,
                                  color: Colors.red,
                                  isSelected: _selectedType == FeedbackType.negative,
                                  onTap: () => setState(() => _selectedType = FeedbackType.negative),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            // Use Expanded here — this Column is inside a Card which has bounded height (CrossAxisAlignment.stretch)
                            Expanded(
                              child: CustomTextField(
                                controller: _textController,
                                hint: 'Tell us more about your experience or the issue you are facing...',
                                maxLines: null,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickFiles,
                                  icon: const Icon(LucideIcons.paperclip, size: 18),
                                  label: const Text('Attach Files'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                                    foregroundColor: theme.primaryColor,
                                    overlayColor: theme.primaryColor.withOpacity(0.15),
                                    elevation: 0,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _captureScreenshot,
                                  icon: const Icon(LucideIcons.camera, size: 18),
                                  label: const Text('Screenshot'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                                    foregroundColor: theme.primaryColor,
                                    overlayColor: theme.primaryColor.withOpacity(0.15),
                                    elevation: 0,
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 150,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : _submitFeedback,
                                    child: _isSubmitting
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text('Send Feedback'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right: Attachments
                  Expanded(
                    flex: 1,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Attachments (${_attachments.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _attachments.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(LucideIcons.fileQuestion, size: 48, color: Colors.grey.withOpacity(0.3)),
                                          const SizedBox(height: 12),
                                          const Text('No files attached', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _attachments.length,
                                      separatorBuilder: (_, __) => const Divider(),
                                      itemBuilder: (context, index) {
                                        final file = _attachments[index];
                                        return ListTile(
                                          leading: const Icon(LucideIcons.file),
                                          title: Text(
                                            file.path.split(Platform.pathSeparator).last,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(LucideIcons.x, size: 18, color: Colors.red),
                                            onPressed: () => _removeAttachment(index),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
