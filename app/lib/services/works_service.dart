// lib/services/works_service.dart

import 'dart:typed_data';
import 'serials_db.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorksService {
  // ---------------------------------------------------------------------------
  // Read — public
  // ---------------------------------------------------------------------------

  /// Browse works with optional filters and pagination.
  /// Queries the works_full view which joins taxonomy and author info.
  Future<List<Map<String, dynamic>>> fetchWorks({
    List<String>? typeNames,
    List<String>? tagNames,
    List<String>? themeNames,
    List<String>? kinkNames,
    List<String>? spiceLevelNames,
    List<String>? ffLevelNames,
    List<String>? settingNames,
    String? status,
    bool excludeExplicit = false,
    String sortColumn = 'published_at',
    bool ascending = false,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = SerialsDb.db
        .from('works_full')
        .select('*')
        .neq('status', 'draft');

    if (status != null) query = query.eq('status', status);
    if (excludeExplicit) query = query.neq('content_rating', 'explicit');

    // Array overlap filters — "work has any of these values"
    if (tagNames != null && tagNames.isNotEmpty) {
      query = query.overlaps('tag_names', tagNames);
    }
    if (themeNames != null && themeNames.isNotEmpty) {
      query = query.overlaps('theme_names', themeNames);
    }
    if (kinkNames != null && kinkNames.isNotEmpty) {
      query = query.overlaps('kink_names', kinkNames);
    }
    if (settingNames != null && settingNames.isNotEmpty) {
      query = query.overlaps('setting_names', settingNames);
    }
    // Single-value taxonomy names stored as columns in the view
    if (typeNames != null && typeNames.isNotEmpty) {
      query = query.inFilter('type_name', typeNames);
    }
    if (spiceLevelNames != null && spiceLevelNames.isNotEmpty) {
      query = query.inFilter('spice_level_name', spiceLevelNames);
    }
    if (ffLevelNames != null && ffLevelNames.isNotEmpty) {
      query = query.inFilter('fflevel_name', ffLevelNames);
    }

    final from = page * pageSize;
    final to   = from + pageSize - 1;

    final res = await query
        .order(sortColumn, ascending: ascending)
        .range(from, to);

    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Homepage: newest published works.
  Future<List<Map<String, dynamic>>> fetchRecent({int limit = 12}) async {
    final res = await SerialsDb.db
        .from('works_full')
        .select('*')
        .eq('status', 'ongoing')
        .neq('content_rating', 'explicit') // exclude explicit from default feed
        .order('published_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Homepage: works with most follows (proxy for "featured").
  Future<List<Map<String, dynamic>>> fetchTrending({int limit = 6}) async {
    final res = await SerialsDb.db
        .from('works_full')
        .select('*')
        .neq('status', 'draft')
        .neq('content_rating', 'explicit')
        .order('follow_count', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Single work by URL slug. Returns null if not found or is a draft.
  Future<Map<String, dynamic>?> fetchWorkBySlug(String slug) async {
    final res = await SerialsDb.db
        .from('works_full')
        .select('*')
        .eq('slug', slug)
        .neq('status', 'draft')
        .maybeSingle();
    return res as Map<String, dynamic>?;
  }

  /// All works by a given author (for their profile page).
  Future<List<Map<String, dynamic>>> fetchWorksByAuthor(String authorId) async {
    final res = await SerialsDb.db
        .from('works_full')
        .select('*')
        .eq('author_id', authorId)
        .neq('status', 'draft')
        .order('published_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  // ---------------------------------------------------------------------------
  // Read — author (own works, including drafts)
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchMyWorks() async {
    final uid = SerialsDb.userId;
    if (uid == null) return [];
    final res = await SerialsDb.db
        .from('works_full')
        .select('*')
        .eq('author_id', uid)
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  // ---------------------------------------------------------------------------
  // Write — create / update / delete
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> createWork({
    required String title,
    String? synopsis,
    String? coverUrl,
    String contentRating = 'general',
    int? spiceLevelId,
    int? ffLevelId,
    int? perspectiveId,
    int? typeId,
  }) async {
    final uid = SerialsDb.userId;
    if (uid == null) throw Exception('Not signed in');

    final res = await SerialsDb.db.from('works').insert({
      'title':          title,
      'synopsis':       synopsis,
      'cover_url':      coverUrl,
      'author_id':      uid,
      'content_rating': contentRating,
      'spice_level_id': spiceLevelId,
      'fflevel_id':     ffLevelId,
      'perspective_id': perspectiveId,
      'type_id':        typeId,
      'status':         'draft',
    }).select().single();

    return res as Map<String, dynamic>;
  }

  Future<void> updateWork(String workId, Map<String, dynamic> updates) async {
    await SerialsDb.db
        .from('works')
        .update(updates)
        .eq('id', workId);
  }

  Future<void> deleteWork(String workId) async {
    await SerialsDb.db.from('works').delete().eq('id', workId);
  }

  Future<void> publishWork(String workId) =>
      updateWork(workId, {'status': 'ongoing', 'published_at': DateTime.now().toIso8601String()});

  // ---------------------------------------------------------------------------
  // List on Embre — cross-reference via RPC (see 003_list_on_embre.sql)
  // ---------------------------------------------------------------------------

  /// Creates a public.series row cross-referencing this work and pre-fills
  /// its "Read On" link back to Embre Serials. Returns the new series_id.
  /// Throws if a series with the same title already exists on Embre.
  Future<int> listOnEmbre(String workId) async {
    final res = await SerialsDb.db.rpc('list_work_on_embre', params: {
      'p_work_id': workId,
    });
    return res as int;
  }

  /// Removes the public.series cross-reference. Safe — only ever deletes
  /// rows with source = 'serials', enforced server-side.
  Future<void> unlistFromEmbre(String workId) async {
    await SerialsDb.db.rpc('unlist_work_from_embre', params: {
      'p_work_id': workId,
    });
  }

  // ---------------------------------------------------------------------------
  // Taxonomy junction management
  // Uses DELETE + INSERT pattern to keep it simple and idempotent.
  // ---------------------------------------------------------------------------

  Future<void> setWorkTags(String workId, List<int> tagIds) =>
      _setJunction('work_tags', workId, 'tags_id', tagIds);

  Future<void> setWorkThemes(String workId, List<int> themeIds) =>
      _setJunction('work_themes', workId, 'themes_id', themeIds);

  Future<void> setWorkKinks(String workId, List<int> kinkIds) =>
      _setJunction('work_kinks', workId, 'kinks_id', kinkIds);

  Future<void> setWorkSettings(String workId, List<int> settingIds) =>
      _setJunction('work_settings', workId, 'setting_id', settingIds);

  /// Currently selected multi-value taxonomy IDs for a work, for pre-filling
  /// the edit form's multi-select pickers.
  Future<Map<String, List<int>>> fetchWorkTaxonomySelections(String workId) async {
    final tags     = await SerialsDb.db.from('work_tags').select('tags_id').eq('work_id', workId);
    final themes   = await SerialsDb.db.from('work_themes').select('themes_id').eq('work_id', workId);
    final kinks    = await SerialsDb.db.from('work_kinks').select('kinks_id').eq('work_id', workId);
    final settings = await SerialsDb.db.from('work_settings').select('setting_id').eq('work_id', workId);

    return {
      'tags':     List<int>.from((tags as List).map((r) => r['tags_id'] as int)),
      'themes':   List<int>.from((themes as List).map((r) => r['themes_id'] as int)),
      'kinks':    List<int>.from((kinks as List).map((r) => r['kinks_id'] as int)),
      'settings': List<int>.from((settings as List).map((r) => r['setting_id'] as int)),
    };
  }

  /// Uploads a cover to the shared 'covers' bucket (same bucket used by the
  /// main Embre app). Returns the filename only — store this in cover_url,
  /// not the full URL (matches the existing Embre convention).
  Future<String> uploadCover(String workId, Uint8List bytes, String ext) async {
    final fileName = 'serials/$workId/cover.$ext';
    await SerialsDb.pub.storage.from('covers').uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    return fileName;
  }

  Future<void> _setJunction(
    String table,
    String workId,
    String fkCol,
    List<int> ids,
  ) async {
    // Delete existing rows first
    await SerialsDb.db.from(table).delete().eq('work_id', workId);
    if (ids.isEmpty) return;
    // Insert new rows
    await SerialsDb.db.from(table).insert(
      ids.map((id) => {'work_id': workId, fkCol: id}).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Follow
  // ---------------------------------------------------------------------------

  Future<void> follow(String workId) async {
    final uid = SerialsDb.userId;
    if (uid == null) return;
    await SerialsDb.db.from('work_follows').upsert({
      'user_id': uid,
      'work_id': workId,
    });
  }

  Future<void> unfollow(String workId) async {
    final uid = SerialsDb.userId;
    if (uid == null) return;
    await SerialsDb.db
        .from('work_follows')
        .delete()
        .eq('user_id', uid)
        .eq('work_id', workId);
  }

  Future<bool> isFollowing(String workId) async {
    final uid = SerialsDb.userId;
    if (uid == null) return false;
    final res = await SerialsDb.db
        .from('work_follows')
        .select('id')
        .eq('user_id', uid)
        .eq('work_id', workId)
        .maybeSingle();
    return res != null;
  }

  // ---------------------------------------------------------------------------
  // Reading lists (TBR / reading / read / recommended)
  // ---------------------------------------------------------------------------

  /// Returns the set of list_type values the current user has for this work.
  Future<Set<String>> getListTypes(String workId) async {
    final uid = SerialsDb.userId;
    if (uid == null) return {};
    final res = await SerialsDb.db
        .from('user_work_lists')
        .select('list_type')
        .eq('user_id', uid)
        .eq('work_id', workId);
    return {for (final row in (res as List)) row['list_type'] as String};
  }

  Future<void> addToList(String workId, String listType) async {
    final uid = SerialsDb.userId;
    if (uid == null) return;
    await SerialsDb.db.from('user_work_lists').upsert({
      'user_id':   uid,
      'work_id':   workId,
      'list_type': listType,
    });
  }

  Future<void> removeFromList(String workId, String listType) async {
    final uid = SerialsDb.userId;
    if (uid == null) return;
    await SerialsDb.db
        .from('user_work_lists')
        .delete()
        .eq('user_id', uid)
        .eq('work_id', workId)
        .eq('list_type', listType);
  }
}
