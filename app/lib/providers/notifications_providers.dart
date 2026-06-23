// lib/providers/notifications_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notifications_service.dart';

final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>(
  (ref) => NotificationsService().fetchRecent(),
);

final unreadNotificationCountProvider = FutureProvider<int>(
  (ref) => NotificationsService().fetchUnreadCount(),
);
