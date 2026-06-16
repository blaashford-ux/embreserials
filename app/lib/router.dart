import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/home_page.dart';
import 'pages/browse_page.dart';
import 'pages/work_page.dart';
import 'pages/chapter_read_page.dart';
import 'pages/author_page.dart';
import 'pages/auth/auth_callback_page.dart';
import 'pages/write/write_dashboard_page.dart';
import 'pages/write/chapter_editor_page.dart';
import 'pages/write/work_settings_page.dart';

// Redirects unauthenticated users away from write routes.
String? _authGuard(BuildContext context, GoRouterState state) {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return '/?signin=true';
  return null;
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
    // Public routes
    GoRoute(path: '/',              builder: (c, s) => const HomePage()),
    GoRoute(path: '/browse',        builder: (c, s) => const BrowsePage()),
    GoRoute(path: '/auth/callback', builder: (c, s) => const AuthCallbackPage()),

    GoRoute(
      path: '/work/:slug',
      builder: (c, s) => WorkPage(slug: s.pathParameters['slug']!),
      routes: [
        GoRoute(
          path: 'chapter/:num',
          builder: (c, s) => ChapterReadPage(
            slug:       s.pathParameters['slug']!,
            chapterNum: int.parse(s.pathParameters['num']!),
          ),
        ),
      ],
    ),

    GoRoute(
      path: '/author/:username',
      builder: (c, s) => AuthorPage(username: s.pathParameters['username']!),
    ),

    // Authenticated write routes
    GoRoute(
      path: '/write',
      redirect: _authGuard,
      builder: (c, s) => const WriteDashboardPage(),
      routes: [
        GoRoute(
          path: ':workId',
          redirect: _authGuard,
          builder: (c, s) => WorkSettingsPage(workId: s.pathParameters['workId']!),
          routes: [
            GoRoute(
              path: 'chapter/:chapterId',
              redirect: _authGuard,
              builder: (c, s) => ChapterEditorPage(
                workId:    s.pathParameters['workId']!,
                chapterId: s.pathParameters['chapterId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);