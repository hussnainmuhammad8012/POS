import 'package:flutter/material.dart';

/// Service to notify desktop providers when a mobile update occurs via LocalApiServer
class DataSyncService extends ChangeNotifier {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  /// Monotonic counter incremented on every DB-mutating event.
  /// Companion app polls /sync/version and refreshes when this changes.
  int _dbVersion = 0;
  int get dbVersion => _dbVersion;

  /// Notify that a product was added or stock was updated from a mobile device
  void notifyMobileUpdate() {
    _dbVersion++;
    debugPrint('DataSyncService: DB version → $_dbVersion');
    notifyListeners();
  }
}
