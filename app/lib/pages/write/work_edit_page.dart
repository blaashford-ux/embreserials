// lib/pages/write/work_edit_page.dart
//
// Combines work settings and chapter management into one page with two tabs,
// matching how Embre's manage_panel keeps related admin actions together
// rather than spreading them across separate routes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../../providers/works_providers.dart';
import '../../services/chapters_service.dart';
import '../../services/works_service.dart';
import '../../services/writing_stats_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/writing_pace_panel.dart';

class WorkEditPage extends ConsumerStatefulWidget {
  final String workId;
  const WorkEditPage({super.key, required this.workId});

  @override
  ConsumerState<WorkEditPage> createState() => _WorkEditPageState();
}

class _WorkEditPageState extends ConsumerState<WorkEditPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myWorks = ref.watch(myWorksProvider);

    return AppShell(
      body: myWorks.when(
        data: (works) {
          final work = works.firstWhere(
            (w) => w['id'] == widget.workId,
            orElse: () => <String, dynamic>{},
          );
          if (work.isEmpty) {
            return const Center(child: Text('Work not found.'));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(work['title'] as String,
                        style: Theme.of(context).textTheme.headlineSmall),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/work/${work['slug']}'),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('View Live'),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Settings'),
                  Tab(text: 'Chapters'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _SettingsTab(work: work),
                    _ChaptersTab(workId: widget.workId),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// =============================================================================
// SETTINGS TAB
// =============================================================================

class _SettingsTab extends ConsumerStatefulWidget {
  final Map<String, dynamic> work;
  const _SettingsTab({required this.work});

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  late TextEditingController _titleController;
  late TextEditingController _synopsisController;
  late TextEditingController _targetWordsController;

  String  _contentRating = 'general';
  String  _status        = 'draft';
  int?    _typeId, _spiceLevelId, _ffLevelId, _perspectiveId;
  DateTime? _targetDate;
  bool    _showTargetPublicly = false;
  bool    _showTargetDatePublicly = false;

  List<int> _selectedTags = [];
  List<int> _selectedThemes = [];
  List<int> _selectedKinks = [];
  List<int> _selectedSettings = [];

  bool _loadingSelections = true;
  bool _saving = false;

  String get _workId => widget.work['id'] as String;

  @override
  void initState() {
    super.initState();
    final w = widget.work;
    _titleController       = TextEditingController(text: w['title'] as String?);
    _synopsisController    = TextEditingController(text: w['synopsis'] as String?);
    _targetWordsController = TextEditingController(
        text: (w['target_word_count'] as int?)?.toString() ?? '');
    _contentRating = w['content_rating'] as String? ?? 'general';
    _status        = w['status'] as String? ?? 'draft';
    _typeId        = w['type_id'] as int?;
    _spiceLevelId  = w['spice_level_id'] as int?;
    _ffLevelId     = w['fflevel_id'] as int?;
    _perspectiveId = w['perspective_id'] as int?;
    _showTargetPublicly     = w['show_target_publicly'] == true;
    _showTargetDatePublicly = w['show_target_date_publicly'] == true;
    if (w['target_completion_date'] != null) {
      _targetDate = DateTime.parse(w['target_completion_date'] as String);
    }
    _loadSelections();
  }

  Future<void> _loadSelections() async {
    final sel = await WorksService().fetchWorkTaxonomySelections(_workId);
    if (mounted) {
      setState(() {
        _selectedTags     = sel['tags']!;
        _selectedThemes   = sel['themes']!;
        _selectedKinks    = sel['kinks']!;
        _selectedSettings = sel['settings']!;
        _loadingSelections = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _synopsisController.dispose();
    _targetWordsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await WorksService().updateWork(_workId, {
        'title':           _titleController.text.trim(),
        'synopsis':        _synopsisController.text.trim(),
        'content_rating':  _contentRating,
        'status':          _status,
        'type_id':         _typeId,
        'spice_level_id':  _spiceLevelId,
        'fflevel_id':      _ffLevelId,
        'perspective_id':  _perspectiveId,
        'target_word_count': int.tryParse(_targetWordsController.text),
        'target_completion_date': _targetDate?.toIso8601String().split('T').first,
        'show_target_publicly':      _showTargetPublicly,
        'show_target_date_publicly': _showTargetDatePublicly,
      });
      await WorksService().setWorkTags(_workId, _selectedTags);
      await WorksService().setWorkThemes(_workId, _selectedThemes);
      await WorksService().setWorkKinks(_workId, _selectedKinks);
      await WorksService().setWorkSettings(_workId, _selectedSettings);

      ref.invalidate(myWorksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext   = picked.path.split('.').last;

    final filename = await WorksService().uploadCover(_workId, bytes, ext);
    await WorksService().updateWork(_workId, {'cover_url': filename});
    ref.invalidate(myWorksProvider);
  }

  Future<void> _listOnEmbre() async {
    try {
      await WorksService().listOnEmbre(_workId);
      ref.invalidate(myWorksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listed on Embre')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _unlistFromEmbre() async {
    await WorksService().unlistFromEmbre(_workId);
    ref.invalidate(myWorksProvider);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSelections) {
      return const Center(child: CircularProgressIndicator());
    }

    final typesAsync       = ref.watch(typesProvider);
    final spiceAsync       = ref.watch(spiceLevelsProvider);
    final ffAsync          = ref.watch(ffLevelsProvider);
    final perspectiveAsync = ref.watch(perspectivesProvider);
    final tagsAsync        = ref.watch(tagsListProvider);
    final themesAsync      = ref.watch(themesListProvider);
    final kinksAsync       = ref.watch(kinksListProvider);
    final settingsAsync    = ref.watch(settingsListProvider);

    final listedOnEmbre = widget.work['listed_on_embre'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickCover,
                  child: Stack(
                    children: [
                      CoverImage(
                        coverFilename: widget.work['cover_url'] as String?,
                        width: 120,
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.edit, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _synopsisController,
              decoration: const InputDecoration(labelText: 'Synopsis'),
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _contentRating,
                    decoration: const InputDecoration(labelText: 'Content Rating'),
                    items: const [
                      DropdownMenuItem(value: 'general',  child: Text('General')),
                      DropdownMenuItem(value: 'teen',      child: Text('Teen')),
                      DropdownMenuItem(value: 'mature',    child: Text('Mature')),
                      DropdownMenuItem(value: 'explicit',  child: Text('Explicit (18+)')),
                    ],
                    onChanged: (v) => setState(() => _contentRating = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'draft',     child: Text('Draft')),
                      DropdownMenuItem(value: 'ongoing',   child: Text('Ongoing')),
                      DropdownMenuItem(value: 'hiatus',    child: Text('On Hiatus')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text('Taxonomy', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            typesAsync.when(
              data: (items) => _singleDropdown('Type', items, 'type_id', _typeId,
                  (v) => setState(() => _typeId = v)),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            spiceAsync.when(
              data: (items) => _singleDropdown('Spice Level', items, 'spicelevel_id',
                  _spiceLevelId, (v) => setState(() => _spiceLevelId = v)),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            ffAsync.when(
              data: (items) => _singleDropdown('Same-Sex Level', items, 'fflevel_id',
                  _ffLevelId, (v) => setState(() => _ffLevelId = v)),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            perspectiveAsync.when(
              data: (items) => _singleDropdown('Perspective', items, 'perspective_id',
                  _perspectiveId, (v) => setState(() => _perspectiveId = v)),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            tagsAsync.when(
              data: (items) => _multiPicker(
                  'Tags', items, 'tags_id', _selectedTags,
                  (v) => setState(() => _selectedTags = v)),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            themesAsync.when(
              data: (items) => _multiPicker(
                  'Themes', items, 'themes_id', _selectedThemes,
                  (v) => setState(() => _selectedThemes = v)),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            kinksAsync.when(
              data: (items) => _multiPicker(
                  'Kinks', items, 'kinks_id', _selectedKinks,
                  (v) => setState(() => _selectedKinks = v)),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            settingsAsync.when(
              data: (items) => _multiPicker(
                  'Setting', items, 'setting_id', _selectedSettings,
                  (v) => setState(() => _selectedSettings = v)),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),
            Text('Word Count Target', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _targetWordsController,
              decoration: const InputDecoration(labelText: 'Target word count'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_targetDate == null
                  ? 'No target date set'
                  : 'Target date: ${DateFormat.yMMMd().format(_targetDate!)}'),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show progress bar publicly'),
              value: _showTargetPublicly,
              onChanged: (v) => setState(() => _showTargetPublicly = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show target date publicly'),
              value: _showTargetDatePublicly,
              onChanged: _showTargetPublicly
                  ? (v) => setState(() => _showTargetDatePublicly = v)
                  : null,
            ),

            const SizedBox(height: 16),
            FutureBuilder(
              future: WritingStatsService().computePace(
                authorId: widget.work['author_id'] as String,
                currentWords: widget.work['word_count_total'] as int,
                targetWords: int.tryParse(_targetWordsController.text),
                targetDate: _targetDate,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return WritingPacePanel(pace: snapshot.data!);
              },
            ),

            const SizedBox(height: 32),
            Text('Embre Listing', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (listedOnEmbre)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  const Text('Listed on Embre'),
                  const Spacer(),
                  TextButton(
                    onPressed: _unlistFromEmbre,
                    child: const Text('Delist'),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _listOnEmbre,
                icon: const Icon(Icons.add_link),
                label: const Text('List on Embre'),
              ),

            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Changes'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _singleDropdown(
    String label,
    List<Map<String, dynamic>> items,
    String idKey,
    int? value,
    void Function(int?) onChanged,
  ) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((i) => DropdownMenuItem(
                value: i[idKey] as int,
                child: Text(i['name'] as String),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _multiPicker(
    String label,
    List<Map<String, dynamic>> items,
    String idKey,
    List<int> selected,
    void Function(List<int>) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MultiSelectDialogField<int>(
        title: Text(label),
        buttonText: Text(label),
        items: items
            .map((i) => MultiSelectItem(i[idKey] as int, i['name'] as String))
            .toList(),
        initialValue: selected,
        onConfirm: (values) => onChanged(values),
      ),
    );
  }
}

// =============================================================================
// CHAPTERS TAB
// =============================================================================

class _ChaptersTab extends ConsumerStatefulWidget {
  final String workId;
  const _ChaptersTab({required this.workId});

  @override
  ConsumerState<_ChaptersTab> createState() => _ChaptersTabState();
}

class _ChaptersTabState extends ConsumerState<_ChaptersTab> {
  Future<void> _addChapter() async {
    final chapter = await ChaptersService().createChapter(workId: widget.workId);
    ref.invalidate(allChaptersProvider(widget.workId));
    if (mounted) {
      context.push('/write/${widget.workId}/chapter/${chapter['id']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(allChaptersProvider(widget.workId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _addChapter,
              icon: const Icon(Icons.add),
              label: const Text('New Chapter'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: chaptersAsync.when(
              data: (chapters) => chapters.isEmpty
                  ? const Center(child: Text('No chapters yet.'))
                  : ListView.separated(
                      itemCount: chapters.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => _ChapterListRow(
                        workId: widget.workId,
                        chapter: chapters[i],
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterListRow extends ConsumerWidget {
  final String workId;
  final Map<String, dynamic> chapter;
  const _ChapterListRow({required this.workId, required this.chapter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt        = NumberFormat('#,###');
    final isPublished = chapter['status'] == 'published';

    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        child: Text('${chapter['chapter_number']}'),
      ),
      title: Text(chapter['title'] as String? ?? 'Untitled chapter'),
      subtitle: Text('${fmt.format(chapter['word_count'])} words · '
          '${isPublished ? 'Published' : 'Draft'}'),
      trailing: PopupMenuButton<String>(
        onSelected: (action) async {
          if (action == 'edit') {
            context.push('/write/$workId/chapter/${chapter['id']}');
          } else if (action == 'publish') {
            await ChaptersService().publishChapter(chapter['id'] as String);
            ref.invalidate(allChaptersProvider(workId));
          } else if (action == 'unpublish') {
            await ChaptersService().unpublishChapter(chapter['id'] as String);
            ref.invalidate(allChaptersProvider(workId));
          } else if (action == 'delete') {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete chapter?'),
                content: const Text('This cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                ],
              ),
            );
            if (confirmed == true) {
              await ChaptersService().deleteChapter(chapter['id'] as String);
              ref.invalidate(allChaptersProvider(workId));
            }
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          if (isPublished)
            const PopupMenuItem(value: 'unpublish', child: Text('Unpublish'))
          else
            const PopupMenuItem(value: 'publish', child: Text('Publish')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      onTap: () => context.push('/write/$workId/chapter/${chapter['id']}'),
    );
  }
}
