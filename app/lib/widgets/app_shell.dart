// lib/widgets/app_shell.dart
//
// Shared page chrome: logo, primary nav, notification bell, auth button.
// Each page wraps its body in AppShell rather than building its own AppBar,
// so navigation stays consistent without needing a GoRouter ShellRoute.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'auth_modal.dart';
import 'notification_bell.dart';

class AppShell extends ConsumerWidget {
  final Widget  body;
  final String? title;

  const AppShell({super.key, required this.body, this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            InkWell(
              onTap: () => context.go('/'),
              child: Text('Embre Serials',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            if (isWide) ...[
              const SizedBox(width: 32),
              _NavLink(label: 'Browse', route: '/browse'),
              const SizedBox(width: 16),
              _NavLink(label: 'Write', route: '/write'),
            ],
          ],
        ),
        actions: [
          if (user != null) const NotificationBell(),
          const SizedBox(width: 8),
          if (user == null)
            TextButton(
              onPressed: () => AuthModal.show(context),
              child: const Text('Sign In'),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle_outlined),
              onSelected: (value) async {
                if (value == 'signout') {
                  await AuthService().signOut();
                } else if (value == 'library') {
                  context.push('/library');
                } else if (value == 'write') {
                  context.push('/write');
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'library', child: Text('My Library')),
                const PopupMenuItem(value: 'write',   child: Text('Write')),
                const PopupMenuItem(value: 'signout', child: Text('Sign Out')),
              ],
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: body,
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final String route;
  const _NavLink({required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.push(route),
      child: Text(label),
    );
  }
}
