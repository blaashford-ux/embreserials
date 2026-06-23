// lib/services/taxonomy_service.dart
//
// Fetches shared lookup data from the public schema.
// All taxonomy tables are shared between Embre and Embre Serials.
// Returns raw maps — IDs and names only — for picker widgets.

import 'serials_db.dart';

class TaxonomyService {
  // Single-select (one value per work)
  Future<List<Map<String, dynamic>>> fetchSpiceLevels() =>
      _fetch('spicelevel', 'spicelevel_id', orderBy: 'spicelevel_id');

  Future<List<Map<String, dynamic>>> fetchFFLevels() =>
      _fetch('fflevel', 'fflevel_id', orderBy: 'fflevel_id');

  Future<List<Map<String, dynamic>>> fetchPerspectives() =>
      _fetch('perspective', 'perspective_id', orderBy: 'perspective_id');

  Future<List<Map<String, dynamic>>> fetchTypes() =>
      _fetch('type', 'type_id', orderBy: 'name');

  // Multi-select (many values per work via junction tables)
  Future<List<Map<String, dynamic>>> fetchTags() =>
      _fetch('tags', 'tags_id', orderBy: 'name');

  Future<List<Map<String, dynamic>>> fetchThemes() =>
      _fetch('themes', 'themes_id', orderBy: 'name');

  Future<List<Map<String, dynamic>>> fetchKinks() =>
      _fetch('kinks', 'kinks_id', orderBy: 'name');

  Future<List<Map<String, dynamic>>> fetchSettings() =>
      _fetch('setting', 'setting_id', orderBy: 'name');

  Future<List<Map<String, dynamic>>> _fetch(
    String table,
    String idCol, {
    required String orderBy,
  }) async {
    final res = await SerialsDb.pub
        .from(table)
        .select('$idCol, name')
        .order(orderBy);
    return List<Map<String, dynamic>>.from(res as List);
  }
}
