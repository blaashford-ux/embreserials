// lib/services/chapters_service.dart

import 'serials_db.dart';

class ChaptersService {
  // ---------------------------------------------------------------------------
  // Read — public (published + visible chapters only)
  // ---------------------------------------------------------------------------

  /// Published chapters for a work, ordered for readers.
  Future<List<Map<String, dynamic>>> fetchPublishedChapters(
      String workId) async {
    final res = await SerialsDb.db
        .from('chapters')
        .select('id, chapter_number, title, word_count, published_at, '
            'author_note_pre, author_note_post')
        .eq('work_id', workId)
        .eq('status', 'published')
        .eq('stub_visible', true)
        .order('chapter_number');
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Single published chapter by work + chapter number.
  /// Returns null if the chapter is stubbed or not published.
  Future<Map<String, dynamic>?> fetchChapter(
      String workId, int chapterNumber) async {
    final res = await SerialsDb.db
        .from('chapters')
        .select('*')
        .eq('work_id', workId)
        .eq('chapter_number', chapterNumber)
        .eq('status', 'published')
        .eq('stub_visible', true)
        .maybeSingle();
    return res as Map<String, dynamic>?;
  }

  // ---------------------------------------------------------------------------
  // Read — author (all chapters including drafts)
  // ---------------------------------------------------------------------------

  /// All chapters for a work regardless of status. Author view only.
  Future<List<Map<String, dynamic>>> fetchAllChapters(String workId) async {
    final res = await SerialsDb.db
        .from('chapters')
        .select('id, chapter_number, title, word_count, status, '
            'published_at, created_at, updated_at')
        .eq('work_id', workId)
        .order('chapter_number');
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Single chapter by ID for the editor. Author access only (RLS enforced).
  Future<Map<String, dynamic>?> fetchChapterById(String chapterId) async {
    final res = await SerialsDb.db
        .from('chapters')
        .select('*')
        .eq('id', chapterId)
        .maybeSingle();
    return res as Map<String, dynamic>?;
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Creates a new draft chapter. Returns the created row.
  Future<Map<String, dynamic>> createChapter({
    required String workId,
    String? title,
    String? authorNotePre,
    String? authorNotePost,
  }) async {
    // Determine next chapter number
    final existing = await fetchAllChapters(workId);
    final nextNum  = existing.isEmpty
        ? 1
        : (existing
                .map((c) => c['chapter_number'] as int)
                .reduce((a, b) => a > b ? a : b) +
            1);

    final res = await SerialsDb.db.from('chapters').insert({
      'work_id':          workId,
      'chapter_number':   nextNum,
      'title':            title,
      'author_note_pre':  authorNotePre,
      'author_note_post': authorNotePost,
      'status':           'draft',
    }).select().single();

    return res as Map<String, dynamic>;
  }

  /// Saves chapter content + word count. Called on autosave and manual save.
  Future<void> saveChapter({
    required String chapterId,
    required List<dynamic> contentJson,  // Quill Delta as JSON list
    required String contentText,         // plaintext shadow
    required int wordCount,
    String? title,
    String? authorNotePre,
    String? authorNotePost,
  }) async {
    await SerialsDb.db.from('chapters').update({
      'content_json':     contentJson,
      'content_text':     contentText,
      'word_count':       wordCount,
      if (title != null)           'title':            title,
      if (authorNotePre != null)   'author_note_pre':  authorNotePre,
      if (authorNotePost != null)  'author_note_post': authorNotePost,
    }).eq('id', chapterId);
  }

  /// Publishes a chapter (sets status + published_at).
  Future<void> publishChapter(String chapterId) async {
    await SerialsDb.db.from('chapters').update({
      'status':       'published',
      'published_at': DateTime.now().toIso8601String(),
    }).eq('id', chapterId);
  }

  /// Reverts a published chapter back to draft.
  Future<void> unpublishChapter(String chapterId) async {
    await SerialsDb.db.from('chapters').update({
      'status':       'draft',
      'published_at': null,
    }).eq('id', chapterId);
  }

  Future<void> deleteChapter(String chapterId) async {
    await SerialsDb.db.from('chapters').delete().eq('id', chapterId);
  }
}
