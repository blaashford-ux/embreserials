// lib/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/home_page.dart';
import 'pages/browse_page.dart';
import 'pages/work_page.dart';
import 'pages/chapter_read_page.dart';
import 'pages/author_page.dart';
import 'pages/library_page.dart';
import 'pages/work_redirect_page.dart';
import 'pages/auth/auth_callback_page.dart';
import 'pages/write/write_dashboard_page.dart';
import 'pages/write/work_edit_page.dart';
import 'pages/write/chapter_editor_page.dart';

// Redirects unauthenticated users away from write/library routes.
String? _authGuard(BuildContext context, GoRouterState state) {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return '/?signin=true';
  return null;
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
    // ---------------------------------------------------------------------
    // Public routes
    // ---------------------------------------------------------------------
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

    // Resolves a work UUID (from notifications) to its slug, then redirects.
    // Declared before /work/:slug-shaped routes would be ambiguous, but since
    // this segment is literally 'work-redirect' it never collides with a slug.
    GoRoute(
      path: '/work-redirect/:workId',
      builder: (c, s) => WorkRedirectPage(workId: s.pathParameters['workId']!),
    ),

    // ---------------------------------------------------------------------
    // Authenticated routes
    // ---------------------------------------------------------------------
    GoRoute(
      path: '/library',
      redirect: _authGuard,
      builder: (c, s) => const LibraryPage(),
    ),

    GoRoute(
      path: '/write',
      redirect: _authGuard,
      builder: (c, s) => const WriteDashboardPage(),
      routes: [
        GoRoute(
          path: ':workId',
          redirect: _authGuard,
          builder: (c, s) => WorkEditPage(workId: s.pathParameters['workId']!),
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
