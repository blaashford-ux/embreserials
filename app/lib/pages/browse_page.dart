// lib/pages/browse_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../providers/works_providers.dart';
import '../services/works_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/work_card.dart';

const _pageSize = 20;

class BrowsePage extends ConsumerStatefulWidget {
  const BrowsePage({super.key});

  @override
  ConsumerState<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends ConsumerState<BrowsePage> {
  final _pagingController =
      PagingController<int, Map<String, dynamic>>(firstPageKey: 0);

  // Active filter selections
  List<String> _typeNames  = [];
  List<String> _tagNames   = [];
  List<String> _themeNames = [];
  bool         _includeExplicit = false;
  String       _sortColumn = 'published_at';
  bool         _ascending  = false;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final items = await WorksService().fetchWorks(
        typeNames:       _typeNames.isEmpty ? null : _typeNames,
        tagNames:        _tagNames.isEmpty ? null : _tagNames,
        themeNames:      _themeNames.isEmpty ? null : _themeNames,
        excludeExplicit: !_includeExplicit,
        sortColumn:      _sortColumn,
        ascending:       _ascending,
        page:            pageKey,
        pageSize:        _pageSize,
      );
      final isLastPage = items.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(items);
      } else {
        _pagingController.appendPage(items, pageKey + 1);
      }
    } catch (e) {
      _pagingController.error = e;
    }
  }

  void _applyFilters() {
    _pagingController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: Column(
        children: [
          _filterBar(context),
          const Divider(height: 1),
          Expanded(
            child: PagedGridView<int, Map<String, dynamic>>(
              pagingController: _pagingController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.55,
              ),
              builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
                itemBuilder: (_, work, __) => WorkCard(work: work, width: 160),
                noItemsFoundIndicatorBuilder: (_) =>
                    const Center(child: Text('No works match these filters.')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar(BuildContext context) {
    final typesAsync  = ref.watch(typesProvider);
    final tagsAsync   = ref.watch(tagsListProvider);
    final themesAsync = ref.watch(themesListProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: typesAsync.when(
              data: (items) => _multiSelectField(
                'Type', items, 'type_id', _typeNames,
                (v) => setState(() => _typeNames = v),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          SizedBox(
            width: 160,
            child: tagsAsync.when(
              data: (items) => _multiSelectField(
                'Tags', items, 'tags_id', _tagNames,
                (v) => setState(() => _tagNames = v),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          SizedBox(
            width: 160,
            child: themesAsync.when(
              data: (items) => _multiSelectField(
                'Themes', items, 'themes_id', _themeNames,
                (v) => setState(() => _themeNames = v),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          FilterChip(
            label: const Text('Show Explicit'),
            selected: _includeExplicit,
            onSelected: (v) {
              setState(() => _includeExplicit = v);
              _applyFilters();
            },
          ),
          DropdownButton<String>(
            value: _sortColumn,
            items: const [
              DropdownMenuItem(value: 'published_at', child: Text('Recently Updated')),
              DropdownMenuItem(value: 'follow_count',  child: Text('Most Followed')),
              DropdownMenuItem(value: 'word_count_total', child: Text('Word Count')),
              DropdownMenuItem(value: 'created_at',    child: Text('Newest')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _sortColumn = v);
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  /// Multi-select field that resolves IDs to names on confirm, since the
  /// works_full view filters by taxonomy name (tag_names etc.), not ID.
  Widget _multiSelectField(
    String label,
    List<Map<String, dynamic>> items,
    String idKey,
    List<String> selectedNames,
    void Function(List<String>) onChanged,
  ) {
    final nameById = {for (final i in items) i[idKey] as int: i['name'] as String};
    final idByName = {for (final i in items) i['name'] as String: i[idKey] as int};
    final selectedIds = selectedNames.map((n) => idByName[n]).whereType<int>().toList();

    return MultiSelectDialogField<int>(
      title: Text(label),
      buttonText: Text(selectedNames.isEmpty ? label : '$label (${selectedNames.length})'),
      items: items.map((i) => MultiSelectItem(i[idKey] as int, i['name'] as String)).toList(),
      initialValue: selectedIds,
      onConfirm: (values) {
        onChanged(values.map((id) => nameById[id]!).toList());
        _applyFilters();
      },
    );
  }
}
