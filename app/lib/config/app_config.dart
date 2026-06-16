// lib/config/app_config.dart

class AppConfig {
  // Shared Supabase project (same as main Embre -- do not create a second project)
  static const String supabaseUrl     = 'https://jqcxnepjkdaklzxltwrm.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_f11tgD__f3PZTLQuXDOv6w_0ACVP6Ad';

  // Hardcoded -- SupabaseClient has no storageUrl / supabaseUrl getters
  static const String storageUrl =
      'https://jqcxnepjkdaklzxltwrm.supabase.co/storage/v1/object/public';

  static const String appName      = 'Embre Serials';
  static const String appUrl       = 'https://serials.embre.net';
  static const String mainEmbreUrl = 'https://embre.net';

  // Shared with main Embre -- covers stored once, referenced by both apps
  static const String coversBucket = 'covers';

  // Kindle standard portrait ratio 1:1.6 (width:height)
  static const double coverAspectRatio = 1 / 1.6;

  /// Full URL for a cover stored as filename only in the database.
  static String coverUrl(String filename) =>
      '$storageUrl/$coversBucket/$filename';
}