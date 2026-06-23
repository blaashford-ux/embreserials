// lib/widgets/notification_bell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/notifications_providers.dart';
import '../services/notifications_service.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unread = unreadAsync.value ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _openSheet(context, ref),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NotificationSheet(),
    ).then((_) {
      // Refresh badge count after the sheet closes
      ref.invalidate(unreadNotificationCountProvider);
    });
  }
}

class _NotificationSheet extends ConsumerWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () async {
                    await NotificationsService().markAllAsRead();
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadNotificationCountProvider);
                  },
                  child: const Text('Mark all read'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: notificationsAsync.when(
              data: (items) => items.isEmpty
                  ? const Center(child: Text('No notifications yet'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (_, i) => _NotificationTile(item: items[i]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final Map<String, dynamic> item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead   = item['is_read'] == true;
    final createdAt = DateTime.parse(item['created_at'] as String);

    return ListTile(
      leading: Icon(
        Icons.menu_book_outlined,
        color: isRead
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Theme.of(context).colorScheme.secondary,
      ),
      title: Text(
        item['message'] as String,
        style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.w600),
      ),
      subtitle: Text(DateFormat.yMMMd().add_jm().format(createdAt)),
      onTap: () async {
        if (!isRead) {
          await NotificationsService().markAsRead(item['id'] as String);
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadNotificationCountProvider);
        }
        final workId = item['work_id'] as String?;
        if (workId != null && context.mounted) {
          Navigator.of(context).pop();
          // Caller is responsible for having a router available at root;
          // work detail navigation by ID is resolved via slug lookup there.
          context.push('/work-redirect/$workId');
        }
      },
    );
  }
}
