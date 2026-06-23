// lib/services/serials_db.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// Access point for all Supabase queries in Embre Serials.
///
/// [db]  — query builder scoped to the 'serials' schema via the
///         documented .schema() method. This is the SAME underlying
///         client/session as [pub] — not a second client instance.
///         Use this for all serials.* tables, views, and RPC calls.
///
/// [pub] — The shared Supabase.instance.client (public schema + auth).
///         Use this for public.* taxonomy tables and all auth calls.
class SerialsDb {
  SerialsDb._();

  /// Main client — public schema + shared auth.
  static SupabaseClient get pub => Supabase.instance.client;

  /// Query builder for the serials schema. No explicit return type here —
  /// let the analyzer infer it, since the exact class name returned by
  /// .schema() can vary slightly between supabase_flutter versions.
  static get db => pub.schema('serials');

  /// Shortcut: current authenticated user ID, or null.
  static String? get userId => pub.auth.currentUser?.id;

  /// Shortcut: whether a user is signed in.
  static bool get isSignedIn => pub.auth.currentUser != null;
}