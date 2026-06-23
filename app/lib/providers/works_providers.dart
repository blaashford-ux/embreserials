// lib/providers/works_providers.dart
//
// Follows the same pattern as Embre's series_providers.dart:
//   - @immutable filter class with == / hashCode using listEquals
//   - FutureProvider.family keyed on the filter
//   - One provider per distinct query

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/works_service.dart';
import '../services/chapters_service.dart';
import '../services/taxonomy_service.dart';

// ---------------------------------------------------------------------------
// WorkFilter — immutable key for filteredWorksProvider
// ---------------------------------------------------------------------------

@immutable
class WorkFilter {
  final List<String>? typeNames;
  final List<String>? tagNames;
  final List<String>? themeNames;
  final List<String>? kinkNames;
  final List<String>? spiceLevelNames;
  final List<String>? ffLevelNames;
  final List<String>? settingNames;
  final String?       status;
  final bool          excludeExplicit;
  final String        sortColumn;
  final bool          ascending;

  const WorkFilter({
    this.typeNames,
    this.tagNames,
    this.themeNames,
    this.kinkNames,
    this.spiceLevelNames,
    this.ffLevelNames,
    this.settingNames,
    this.status,
    this.excludeExplicit = false,
    this.sortColumn      = 'published_at',
    this.ascending       = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkFilter &&
          runtimeType == other.runtimeType &&
          listEquals(typeNames,        other.typeNames) &&
          listEquals(tagNames,         other.tagNames) &&
          listEquals(themeNames,       other.themeNames) &&
          listEquals(kinkNames,        other.kinkNames) &&
          listEquals(spiceLevelNames,  other.spiceLevelNames) &&
          listEquals(ffLevelNames,     other.ffLevelNames) &&
          listEquals(settingNames,     other.settingNames) &&
          status          == other.status &&
          excludeExplicit == other.excludeExplicit &&
          sortColumn      == other.sortColumn &&
          ascending       == other.ascending;

  @override
  int get hashCode => Object.hashAll([
        ...?typeNames,
        ...?tagNames,
        ...?themeNames,
        ...?kinkNames,
        ...?spiceLevelNames,
        ...?ffLevelNames,
        ...?settingNames,
        status,
        excludeExplicit,
        sortColumn,
        ascending,
      ]);
}

// ---------------------------------------------------------------------------
// Work list providers
// ---------------------------------------------------------------------------

/// Paginated filtered works for the browse page.
/// Pass page index as the second element of the family key if needed;
/// for now browse uses page 0 and loads more via PagingController.
final filteredWorksProvider =
    FutureProvider.family<List<Map<String, dynamic>>, WorkFilter>(
  (ref, filter) => WorksService().fetchWorks(
    typeNames:       filter.typeNames,
    tagNames:        filter.tagNames,
    themeNames:      filter.themeNames,
    kinkNames:       filter.kinkNames,
    spiceLevelNames: filter.spiceLevelNames,
    ffLevelNames:    filter.ffLevelNames,
    settingNames:    filter.settingNames,
    status:          filter.status,
    excludeExplicit: filter.excludeExplicit,
    sortColumn:      filter.sortColumn,
    ascending:       filter.ascending,
  ),
);

/// Homepage: recently updated ongoing works.
final recentWorksProvider =
    FutureProvider<List<Map<String, dynamic>>>(
  (ref) => WorksService().fetchRecent(),
);

/// Homepage: most-followed works.
final trendingWorksProvider =
    FutureProvider<List<Map<String, dynamic>>>(
  (ref) => WorksService().fetchTrending(),
);

/// Work detail by URL slug.
final workBySlugProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, slug) => WorksService().fetchWorkBySlug(slug),
);

/// Author page: all works by a given author ID.
final worksByAuthorProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, authorId) => WorksService().fetchWorksByAuthor(authorId),
);

/// Writing dashboard: logged-in author's own works (incl. drafts).
final myWorksProvider =
    FutureProvider<List<Map<String, dynamic>>>(
  (ref) => WorksService().fetchMyWorks(),
);

// ---------------------------------------------------------------------------
// Chapter providers
// ---------------------------------------------------------------------------

/// Published chapters for a work (reader view).
final publishedChaptersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, workId) => ChaptersService().fetchPublishedChapters(workId),
);

/// All chapters for a work (author view, includes drafts).
final allChaptersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, workId) => ChaptersService().fetchAllChapters(workId),
);

/// Single chapter for the editor.
final chapterByIdProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, chapterId) => ChaptersService().fetchChapterById(chapterId),
);

// ---------------------------------------------------------------------------
// Taxonomy providers (for pickers in WorkEditPage)
// ---------------------------------------------------------------------------

final spiceLevelsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => TaxonomyService().fetchSpiceLevels());

final ffLevelsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => TaxonomyService().fetchFFLevels());

final perspectivesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => TaxonomyService().fetchPerspectives());

final typesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => TaxonomyService().fetchTypes());

final tagsListProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => TaxonomyService().fetchTags());

final themesListProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => TaxonomyService().fetchThemes());

final kinksListProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => TaxonomyService().fetchKinks());

final settingsListProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => TaxonomyService().fetchSettings());
