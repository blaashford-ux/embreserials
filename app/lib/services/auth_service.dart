// lib/services/auth_service.dart
//
// Adapted from the main Embre AuthService.
// Same Supabase project, same users, same OAuth providers.
// Differences: app origin, deep-link scheme, age-confirmation methods.

import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'serials_db.dart';

class AuthService {
  final _auth = SerialsDb.pub.auth;

  // ---------------------------------------------------------------------------
  // Origin / callback URL
  // ---------------------------------------------------------------------------

  static const String _appOrigin = String.fromEnvironment(
    'APP_ORIGIN',
    defaultValue: 'https://serials.embre.net',
  );

  /// On web, use the actual browser origin so preview/staging deployments
  /// work without a separate build flag.
  String get _currentOrigin {
    if (kIsWeb) {
      final host = html.window.location.hostname ?? '';
      if (host.endsWith('.pages.dev') || host.endsWith('.embre.net')) {
        return html.window.location.origin ?? _appOrigin;
      }
    }
    return _appOrigin;
  }

  String get _callbackUrl => kIsWeb
      ? '$_currentOrigin/auth/callback'
      : 'net.embre.serials://login-callback';

  // ---------------------------------------------------------------------------
  // Auth state
  // ---------------------------------------------------------------------------

  bool get isAuthenticated => _auth.currentUser != null;
  User? get currentUser    => _auth.currentUser;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // Email / password
  // ---------------------------------------------------------------------------

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final res = await _auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'full_name': displayName},
    );
    if (res.user == null) throw Exception('Sign up failed');
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  // ---------------------------------------------------------------------------
  // OAuth  (same behaviour as Embre: web awaits, mobile launches + returns)
  // ---------------------------------------------------------------------------

  Future<void> signInWithGoogle() => _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _callbackUrl,
        authScreenLaunchMode: LaunchMode.platformDefault,
      );

  Future<void> signInWithDiscord() => _auth.signInWithOAuth(
        OAuthProvider.discord,
        redirectTo: _callbackUrl,
        authScreenLaunchMode: LaunchMode.platformDefault,
      );

  // ---------------------------------------------------------------------------
  // Age confirmation gate
  // ---------------------------------------------------------------------------

  /// Returns true if the current user has confirmed they are 18+.
  /// Reads from public.users.age_confirmed added in the schema migration.
  Future<bool> isAgeConfirmed() async {
    final uid = currentUser?.id;
    if (uid == null) return false;
    try {
      final row = await SerialsDb.pub
          .from('users')
          .select('age_confirmed')
          .eq('id', uid)
          .maybeSingle();
      return row?['age_confirmed'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Persists age confirmation. Called once from the AgeGateModal.
  Future<void> confirmAge() async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    await SerialsDb.pub.from('users').update({
      'age_confirmed': true,
      'age_confirmed_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);
  }

  // ---------------------------------------------------------------------------
  // Avatar (kept for profile page parity with Embre)
  // ---------------------------------------------------------------------------

  Future<String> uploadAvatar(File imageFile) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    final ext      = imageFile.path.split('.').last;
    final fileName = '$uid/avatar.$ext';
    try {
      await SerialsDb.pub.storage.from('avatars').remove([fileName]);
    } catch (_) {}
    await SerialsDb.pub.storage.from('avatars').upload(
      fileName,
      imageFile,
      fileOptions: const FileOptions(upsert: true),
    );
    return SerialsDb.pub.storage.from('avatars').getPublicUrl(fileName);
  }
}
