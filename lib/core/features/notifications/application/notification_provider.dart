import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../models/notification_model.dart';
import '../../../repositories/notification_repository.dart';
import '../../../../features/pos/application/pos_provider.dart';
import '../../../../core/database/app_database.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  NotificationProvider(this._repository) {
    _loadNotifications();
  }

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> _loadNotifications() async {
    _notifications = await _repository.getAllNotifications();
    _unreadCount = await _repository.getUnreadCount();
    notifyListeners();
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    String? payload,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await _repository.insertNotification(notification);
    await _loadNotifications();
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    await _loadNotifications();
  }

  Future<void> deleteNotification(String id) async {
    await _repository.deleteNotification(id);
    await _loadNotifications();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    await _loadNotifications();
  }
  // notifications 
  /// Check for overdue credits and generate notifications
  Future<void> checkOverdueCredits() async {
    final db = AppDatabase.instance.db;
    final now = DateTime.now().toIso8601String();
    
    // Join credit_ledgers with customers to get the customer name
    final List<Map<String, dynamic>> overdueLedgers = await db.rawQuery('''
      SELECT cl.*, c.name as customer_name
      FROM credit_ledgers cl
      JOIN customers c ON cl.customer_id = c.id
      WHERE cl.type = 'CREDIT' 
      AND cl.due_date IS NOT NULL 
      AND cl.due_date < ?
      AND NOT EXISTS (
        SELECT 1 FROM notifications n 
        WHERE n.type = 'CREDIT_REMINDER' 
        AND n.payload LIKE '%"ledgerId":"' || cl.id || '"%'
      )
    ''', [now]);

    for (var ledger in overdueLedgers) {
      final customerName = ledger['customer_name'];
      final amount = ledger['amount'];
      final ledgerId = ledger['id'];
      final customerId = ledger['customer_id'];

      await addNotification(
        title: 'Credit Overdue',
        message: 'Credit of Rs $amount for $customerName is overdue.',
        type: 'CREDIT_REMINDER',
        payload: jsonEncode({
          'ledgerId': ledgerId,
          'customerId': customerId,
        }),
      );
    }
  }

  /// Check for low stock items and generate notifications
  Future<void> checkLowStock() async {
    final db = AppDatabase.instance.db;
    
    final List<Map<String, dynamic>> lowStockItems = await db.rawQuery('''
      SELECT sl.product_variant_id, p.name as product_name, sl.available_pieces, sl.low_stock_threshold
      FROM stock_levels sl
      JOIN product_variants pv ON sl.product_variant_id = pv.id
      JOIN products p ON pv.product_id = p.id
      WHERE sl.available_pieces <= sl.low_stock_threshold
      AND NOT EXISTS (
        SELECT 1 FROM notifications n 
        WHERE n.type = 'LOW_STOCK' 
        AND n.payload LIKE '%"variantId":"' || sl.product_variant_id || '"%'
      )
    ''');

    for (var item in lowStockItems) {
      final productName = item['product_name'];
      final available = item['available_pieces'];
      final variantId = item['product_variant_id'];

      await addNotification(
        title: 'Low Stock Alert',
        message: '$productName is low on stock ($available pieces remaining).',
        type: 'LOW_STOCK',
        payload: jsonEncode({
          'variantId': variantId,
        }),
      );
    }
  }
}
