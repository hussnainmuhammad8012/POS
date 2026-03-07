import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/app_database.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  Database get _db => AppDatabase.instance.db;

  Future<void> insertNotification(AppNotification notification) async {
    await _db.insert('notifications', notification.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AppNotification>> getAllNotifications() async {
    final List<Map<String, dynamic>> maps = await _db.query('notifications',
        orderBy: 'created_at DESC');
    return maps.map((m) => AppNotification.fromMap(m)).toList();
  }

  Future<void> markAsRead(String id) async {
    await _db.update('notifications', {'is_read': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteNotification(String id) async {
    await _db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    await _db.delete('notifications');
  }

  Future<int> getUnreadCount() async {
    final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM notifications WHERE is_read = 0');
    return result.first['count'] as int;
  }
}
