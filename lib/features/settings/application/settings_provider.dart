import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/database_backup_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsProvider(this._prefs);

  // Store Information
  String get storeName => _prefs.getString('store_name') ?? 'Utility POS Central';
  String get storeAddress => _prefs.getString('store_address') ?? '123 Main Street';
  String get storePhone => _prefs.getString('store_phone') ?? '+92 300 1234567';
  double get taxRate => _prefs.getDouble('tax_rate') ?? 18.0;

  // Receipt Options
  String get receiptCustomMessage => _prefs.getString('receipt_custom_message') ?? 'Thank you for shopping with us!';

  // Payment Methods
  List<String> get paymentMethods {
    final List<String>? methods = _prefs.getStringList('payment_methods');
    if (methods == null || methods.isEmpty) {
      return ['CASH', 'JAZZCASH', 'BANK'];
    }
    return methods;
  }

  // Backup Settings
  bool get autoBackupEnabled => _prefs.getBool('auto_backup_enabled') ?? true;
  String? get lastBackupDate => _prefs.getString('last_backup_date');

  // Companion App Server Settings
  bool get isServerEnabled => _prefs.getBool('is_server_enabled') ?? false;
  int get sessionDurationHours => _prefs.getInt('session_duration_hours') ?? 24;
  bool get dailyReportEnabled => _prefs.getBool('daily_report_enabled') ?? true;
  String get dailyReportTime => _prefs.getString('daily_report_time') ?? '20:00';
  String? get adminFcmToken => _prefs.getString('admin_fcm_token');

  // Supplier Settings
  bool get isSupplierLedgerEnabled => _prefs.getBool('is_supplier_ledger_enabled') ?? true;

  final _backupService = DatabaseBackupService();

  // Setters
  Future<void> updateStoreInfo({
    String? name,
    String? address,
    String? phone,
    double? tax,
  }) async {
    if (name != null) await _prefs.setString('store_name', name);
    if (address != null) await _prefs.setString('store_address', address);
    if (phone != null) await _prefs.setString('store_phone', phone);
    if (tax != null) await _prefs.setDouble('tax_rate', tax);
    notifyListeners();
  }

  Future<void> updateReceiptMessage(String message) async {
    await _prefs.setString('receipt_custom_message', message);
    notifyListeners();
  }

  Future<void> setAutoBackup(bool enabled) async {
    await _prefs.setBool('auto_backup_enabled', enabled);
    notifyListeners();
  }

  // Backup & Restore Actions
  Future<void> manualExport(String targetPath) async {
    await _backupService.exportDatabase(targetPath);
    await _updateLastBackupTimestamp();
  }

  Future<void> restoreBackup(String sourcePath) async {
    await _backupService.restoreDatabase(sourcePath);
    notifyListeners(); // Refresh UI after database change
  }

  Future<void> clearDatabase() async {
    await _backupService.clearDatabase();
    notifyListeners();
  }

  Future<void> checkAndPerformAutoBackup() async {
    if (!autoBackupEnabled) return;

    final now = DateTime.now();
    final lastStr = lastBackupDate;
    
    bool needsBackup = false;
    if (lastStr == null) {
      needsBackup = true;
    } else {
      final last = DateTime.parse(lastStr);
      if (now.difference(last).inDays >= 1) {
        needsBackup = true;
      }
    }

    if (needsBackup) {
      try {
        final currentDir = Directory.current;
        final backupDir = Directory(p.join(currentDir.path, 'backups', 'auto'));
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        
        final timestamp = now.toIso8601String().replaceAll(':', '-').split('.').first;
        final targetPath = p.join(backupDir.path, 'auto_backup_$timestamp.db');
        
        await _backupService.exportDatabase(targetPath);
        await _updateLastBackupTimestamp();
        print('Auto-backup completed: $targetPath');
      } catch (e) {
        print('Auto-backup failed: $e');
      }
    }
  }

  Future<void> _updateLastBackupTimestamp() async {
    await _prefs.setString('last_backup_date', DateTime.now().toIso8601String());
    notifyListeners();
  }

  Future<void> addPaymentMethod(String method) async {
    final methods = List<String>.from(paymentMethods);
    final upperMethod = method.toUpperCase();
    if (!methods.contains(upperMethod)) {
      methods.add(upperMethod);
      await _prefs.setStringList('payment_methods', methods);
      notifyListeners();
    }
  }

  Future<void> removePaymentMethod(String method) async {
    final methods = List<String>.from(paymentMethods);
    final upperMethod = method.toUpperCase();
    if (upperMethod != 'CASH') {
      methods.remove(upperMethod);
      await _prefs.setStringList('payment_methods', methods);
      notifyListeners();
    }
  }

  Future<void> resetToDefaults() async {
    await _prefs.clear();
    notifyListeners();
  }

  Future<void> setServerEnabled(bool enabled) async {
    await _prefs.setBool('is_server_enabled', enabled);
    notifyListeners();
  }

  Future<void> setSessionDuration(int hours) async {
    await _prefs.setInt('session_duration_hours', hours);
    notifyListeners();
  }

  Future<void> setDailyReportEnabled(bool enabled) async {
    await _prefs.setBool('daily_report_enabled', enabled);
    notifyListeners();
  }

  Future<void> setDailyReportTime(String time) async {
    await _prefs.setString('daily_report_time', time);
    notifyListeners();
  }

  Future<void> setAdminFcmToken(String token) async {
    await _prefs.setString('admin_fcm_token', token);
    notifyListeners();
  }

  Future<void> setSupplierLedgerEnabled(bool enabled) async {
    await _prefs.setBool('is_supplier_ledger_enabled', enabled);
    notifyListeners();
    // Note: The logic to add a SYSTEM_NOTE to ledgers will be handled by the UI / SupplierProvider
    // when calling this method, as SettingsProvider shouldn't depend on SupplierRepository directly.
  }
}
