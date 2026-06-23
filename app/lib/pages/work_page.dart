// lib/pages/work_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/works_providers.dart';
import '../services/works_service.dart';
import '../widgets/age_gate_modal.dart';
import '../widgets/app_shell.dart';
import '../widgets/cover_image.dart';
import '../widgets/word_count_progress.dart';

class WorkPage extends ConsumerStatefulWidget {
  final String slug;
  const WorkPage({super.key, required this.slug});

  @override
  ConsumerState<WorkPage> createState() => _WorkPageState();
}

class _WorkPageState extends ConsumerState<WorkPage> {
  bool _accessChecked = false;
  bool _accessGranted = true;

  @override
  Widget build(BuildContext context) {
    final workAsync = ref.watch(workBySlugProvider(widget.slug));

    return AppShell(
      body: workAsync.when(
        data: (work) {
          if (work == null) {
            return const Center(child: Text('Work not found.'));
          }
          return _checkAccessAndBuild(context, work);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _checkAccessAndBuild(BuildContext context, Map<String, dynamic> work) {
    final isExplicit = work['content_rating'] == 'explicit';

    if (isExplicit && !_accessChecked) {
      // Defer the async age-gate check to after this build completes
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final granted = await AgeGateModal.check(context, ref);
        if (mounted) {
          setState(() {
            _accessChecked = true;
            _accessGranted = granted;
          });
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    if (isExplicit && _accessChecked && !_accessGranted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              const Text('This work is age-restricted (18+).'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return _WorkDetail(work: work);
  }
}

class _WorkDetail extends ConsumerWidget {
  final Map<String, dynamic> work;
  const _WorkDetail({required this.work});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme    = Theme.of(context);
    final workId   = work['id'] as String;
    final user     = ref.watch(currentUserProvider);
    final chapters = ref.watch(publishedChaptersProvider(workId));
    final fmt      = NumberFormat('#,###');

    final allTags = <String>[
      ...List<String>.from(work['tag_names'] ?? []),
      ...List<String>.from(work['theme_names'] ?? []),
      ...List<String>.from(work['kink_names'] ?? []),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CoverImage(coverFilename: work['cover_url'] as String?, width: 180),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(work['title'] as String, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => context.push(
                            '/author/${Uri.encodeComponent(work['author_display_name'] as String)}'),
                        child: Text(
                          'by ${work['author_display_name']}',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: theme.colorScheme.secondary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${fmt.format(work['word_count_total'])} words · '
                        '${work['chapter_count']} chapters · '
                        '${_statusLabel(work['status'] as String)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),

                      if (work['show_target_publicly'] == true)
                        WordCountProgress(
                          currentWords:   work['word_count_total'] as int,
                          targetWords:    work['target_word_count'] as int?,
                          targetDate:     work['target_completion_date'] != null
                              ? DateTime.parse(work['target_completion_date'] as String)
                              : null,
                          showTargetDate: work['show_target_date_publicly'] == true,
                        ),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FollowButton(workId: workId, signedIn: user != null),
                          _ListButton(workId: workId, signedIn: user != null),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (allTags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: allTags
                    .map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],

            Text('Synopsis', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(work['synopsis'] as String? ?? '', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 32),

            Text('Chapters', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            chapters.when(
              data: (list) => list.isEmpty
                  ? const Text('No chapters published yet.')
                  : Column(
                      children: list
                          .map((c) => _ChapterRow(slug: work['slug'] as String, chapter: c))
                          .toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ongoing':   return 'Ongoing';
      case 'completed': return 'Completed';
      case 'hiatus':    return 'On Hiatus';
      case 'stub':      return 'Preview (full story on Amazon)';
      default:          return status;
    }
  }
}

class _ChapterRow extends StatelessWidget {
  final String slug;
  final Map<String, dynamic> chapter;
  const _ChapterRow({required this.slug, required this.chapter});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        'Chapter ${chapter['chapter_number']}'
        '${chapter['title'] != null ? ': ${chapter['title']}' : ''}',
      ),
      subtitle: Text('${fmt.format(chapter['word_count'])} words'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/work/$slug/chapter/${chapter['chapter_number']}'),
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  final String workId;
  final bool   signedIn;
  const _FollowButton({required this.workId, required this.signedIn});

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool? _following;

  @override
  void initState() {
    super.initState();
    if (widget.signedIn) _load();
  }

  Future<void> _load() async {
    final f = await WorksService().isFollowing(widget.workId);
    if (mounted) setState(() => _following = f);
  }

  Future<void> _toggle() async {
    if (!widget.signedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to follow this work')));
      return;
    }
    final newState = !(_following ?? false);
    setState(() => _following = newState);
    if (newState) {
      await WorksService().follow(widget.workId);
    } else {
      await WorksService().unfollow(widget.workId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final following = _following ?? false;
    return OutlinedButton.icon(
      onPressed: _toggle,
      icon: Icon(following ? Icons.notifications_active : Icons.notifications_none),
      label: Text(following ? 'Following' : 'Follow'),
    );
  }
}

class _ListButton extends ConsumerStatefulWidget {
  final String workId;
  final bool   signedIn;
  const _ListButton({required this.workId, required this.signedIn});

  @override
  ConsumerState<_ListButton> createState() => _ListButtonState();
}

class _ListButtonState extends ConsumerState<_ListButton> {
  Set<String> _lists = {};

  @override
  void initState() {
    super.initState();
    if (widget.signedIn) _load();
  }

  Future<void> _load() async {
    final l = await WorksService().getListTypes(widget.workId);
    if (mounted) setState(() => _lists = l);
  }

  Future<void> _toggle(String listType) async {
    if (!widget.signedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to manage your library')));
      return;
    }
    final has = _lists.contains(listType);
    setState(() {
      if (has) {
        _lists.remove(listType);
      } else {
        _lists.add(listType);
      }
    });
    if (has) {
      await WorksService().removeFromList(widget.workId, listType);
    } else {
      await WorksService().addToList(widget.workId, listType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      onSelected: _toggle,
      itemBuilder: (_) => [
        _checkItem('tbr',         'To Be Read'),
        _checkItem('reading',     'Currently Reading'),
        _checkItem('read',        'Read'),
        _checkItem('recommended', 'Recommend'),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border, size: 18),
            const SizedBox(width: 8),
            Text(_lists.isEmpty ? 'Add to Library' : 'In Library (${_lists.length})'),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _checkItem(String value, String label) {
    final checked = _lists.contains(value);
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(checked ? Icons.check_box : Icons.check_box_outline_blank, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
