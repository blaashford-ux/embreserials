// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/serials_db.dart';

// ---------------------------------------------------------------------------
// Auth stream — rebuilds whenever sign-in / sign-out happens
// ---------------------------------------------------------------------------

final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService().authStateChanges;
});

// ---------------------------------------------------------------------------
// Current user — derived from the auth stream
// ---------------------------------------------------------------------------

final currentUserProvider = Provider<User?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data:    (state) => state.session?.user,
    loading: ()      => SerialsDb.pub.auth.currentUser,
    error:   (_, __) => null,
  );
});

// ---------------------------------------------------------------------------
// Age confirmed — re-checked whenever the user changes
// ---------------------------------------------------------------------------

final ageConfirmedProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return AuthService().isAgeConfirmed();
});
