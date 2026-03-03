import 'dart:io';

void main() {
  final dir = Directory('lib');
  for (var file in dir.listSync(recursive: true).whereType<File>()) {
    if (file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      var changed = false;

      // Make sure const is stripped where LucideIcons is used in a const array
      if (content.contains('children: const [')) {
        if (content.contains('LucideIcons')) {
          content = content.replaceAll('children: const [', 'children: [');
          changed = true;
        }
      }

      // Remove const from Icon(LucideIcons...)
      if (content.contains('const Icon(LucideIcons')) {
        content = content.replaceAll('const Icon(LucideIcons', 'Icon(LucideIcons');
        changed = true;
      }
      
      // Fix specific broken icon names
      if (content.contains('LucideIcons.store')) {
        content = content.replaceAll('LucideIcons.store', 'LucideIcons.store');
      }
      if (content.contains('LucideIcons.downloadCloud')) {
        content = content.replaceAll('LucideIcons.downloadCloud', 'LucideIcons.downloadCloud');
      }

      if (changed) {
        file.writeAsStringSync(content);
        print('Updated: \${file.path}');
      }
    }
  }

  // Also fix unused imports in main.dart
  final mainFile = File('lib/main.dart');
  if (mainFile.existsSync()) {
    var mainContent = mainFile.readAsStringSync();
    mainContent = mainContent.replaceAll("import 'features/pos/presentation/pos_screen.dart';", "");
    mainContent = mainContent.replaceAll("import 'features/inventory/presentation/inventory_screen.dart';", "");
    mainContent = mainContent.replaceAll("import 'features/customers/presentation/customers_screen.dart';", "");
    mainContent = mainContent.replaceAll("import 'features/analytics/presentation/analytics_screen.dart';", "");
    mainContent = mainContent.replaceAll("import 'features/settings/presentation/settings_screen.dart';", "");
    mainFile.writeAsStringSync(mainContent);
  }
}
