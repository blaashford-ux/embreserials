// lib/services/notifications_service.dart

import 'serials_db.dart';

class NotificationsService {
  Future<List<Map<String, dynamic>>> fetchRecent({int limit = 30}) async {
    final uid = SerialsDb.userId;
    if (uid == null) return [];
    final res = await SerialsDb.db
        .from('notifications')
        .select('*')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<int> fetchUnreadCount() async {
    final uid = SerialsDb.userId;
    if (uid == null) return 0;
    final res = await SerialsDb.db
        .from('notifications')
        .select('id')
        .eq('user_id', uid)
        .eq('is_read', false);
    return (res as List).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await SerialsDb.db
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final uid = SerialsDb.userId;
    if (uid == null) return;
    await SerialsDb.db
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid)
        .eq('is_read', false);
  }
}
