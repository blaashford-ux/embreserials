// lib/services/writing_stats_service.dart
//
// Computes the author-facing pacing numbers described in the word count spec:
//   required_pace, actual_avg_pace (30d), estimated_completion, on_track.
//
// actual_avg_pace_30d is also cached on works.actual_avg_pace_30d by a
// nightly cron job (for the public progress bar's cheap reads), but the
// writing dashboard always computes it live so authors see today's number.

import 'serials_db.dart';

/// Pure result object — no DB access, easy to test and display.
class WritingPace {
  final int       currentWords;
  final int?      targetWords;
  final DateTime? targetDate;
  final double    actualAvgPace30d; // words/day, 0 if no recent writing
  final double?   requiredPace;     // words/day needed to hit target, null if no target
  final DateTime? estimatedCompletion; // null if actualAvgPace30d == 0
  final bool?      onTrack;          // null if requiredPace can't be computed

  const WritingPace({
    required this.currentWords,
    required this.targetWords,
    required this.targetDate,
    required this.actualAvgPace30d,
    required this.requiredPace,
    required this.estimatedCompletion,
    required this.onTrack,
  });

  int? get wordsRemaining =>
      targetWords == null ? null : (targetWords! - currentWords).clamp(0, targetWords!);
}

class WritingStatsService {
  /// Records today's net word delta for the current author.
  /// In practice this is handled by the DB trigger on chapters.word_count,
  /// but exposed here in case a manual adjustment is ever needed.
  Future<void> recordWordsAdded(String userId, int delta) async {
    if (delta <= 0) return;
    await SerialsDb.db.from('author_writing_stats').upsert({
      'user_id':     userId,
      'stat_date':   DateTime.now().toIso8601String().split('T').first,
      'words_added': delta,
    }, onConflict: 'user_id,stat_date');
  }

  /// Computes the full pacing breakdown for a single work.
  Future<WritingPace> computePace({
    required String   authorId,
    required int       currentWords,
    required int?      targetWords,
    required DateTime? targetDate,
  }) async {
    final avgPace = await _fetch30DayAvgPace(authorId);

    double? requiredPace;
    DateTime? estimatedCompletion;
    bool? onTrack;

    if (targetWords != null) {
      final remaining = (targetWords - currentWords).clamp(0, targetWords);

      if (targetDate != null) {
        final daysRemaining = targetDate.difference(DateTime.now()).inDays;
        if (daysRemaining > 0) {
          requiredPace = remaining / daysRemaining;
        } else {
          requiredPace = remaining.toDouble(); // overdue — all remaining "due now"
        }
      }

      if (avgPace > 0) {
        final daysNeeded = remaining / avgPace;
        estimatedCompletion = DateTime.now().add(Duration(days: daysNeeded.ceil()));
      }

      if (requiredPace != null) {
        onTrack = avgPace >= requiredPace;
      }
    }

    return WritingPace(
      currentWords:        currentWords,
      targetWords:         targetWords,
      targetDate:          targetDate,
      actualAvgPace30d:    avgPace,
      requiredPace:        requiredPace,
      estimatedCompletion: estimatedCompletion,
      onTrack:             onTrack,
    );
  }

  /// Average words/day over the last 30 calendar days (rolling window).
  /// Days with no writing simply don't have a row — divides by 30 regardless,
  /// which correctly reflects a slower pace if the author skipped days.
  Future<double> _fetch30DayAvgPace(String authorId) async {
    final since = DateTime.now().subtract(const Duration(days: 30));
    final res = await SerialsDb.db
        .from('author_writing_stats')
        .select('words_added')
        .eq('user_id', authorId)
        .gte('stat_date', since.toIso8601String().split('T').first);

    final rows = List<Map<String, dynamic>>.from(res as List);
    if (rows.isEmpty) return 0;

    final total = rows.fold<int>(0, (sum, r) => sum + (r['words_added'] as int));
    return total / 30;
  }

  /// Writing heatmap data — words written per day, last N days.
  Future<Map<DateTime, int>> fetchHeatmapData(String authorId, {int days = 365}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final res = await SerialsDb.db
        .from('author_writing_stats')
        .select('stat_date, words_added')
        .eq('user_id', authorId)
        .gte('stat_date', since.toIso8601String().split('T').first)
        .order('stat_date');

    final rows = List<Map<String, dynamic>>.from(res as List);
    return {
      for (final r in rows)
        DateTime.parse(r['stat_date'] as String): r['words_added'] as int,
    };
  }
}
