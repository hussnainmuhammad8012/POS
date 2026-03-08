import 'package:flutter/material.dart';

/// Service to notify desktop providers when a mobile update occurs via LocalApiServer
class DataSyncService extends ChangeNotifier {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  /// Notify that a product was added or stock was updated from a mobile device
  void notifyMobileUpdate() {
    debugPrint('DataSyncService: Notifying mobile update event');
    notifyListeners();
  }
}
