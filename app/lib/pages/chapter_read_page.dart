// lib/pages/chapter_read_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/works_providers.dart';
import '../services/chapters_service.dart';
import '../widgets/age_gate_modal.dart';
import '../widgets/app_shell.dart';

class ChapterReadPage extends ConsumerStatefulWidget {
  final String slug;
  final int    chapterNum;
  const ChapterReadPage({super.key, required this.slug, required this.chapterNum});

  @override
  ConsumerState<ChapterReadPage> createState() => _ChapterReadPageState();
}

class _ChapterReadPageState extends ConsumerState<ChapterReadPage> {
  bool _accessChecked = false;
  bool _accessGranted = true;

  @override
  Widget build(BuildContext context) {
    final workAsync = ref.watch(workBySlugProvider(widget.slug));

    return AppShell(
      body: workAsync.when(
        data: (work) {
          if (work == null) return const Center(child: Text('Work not found.'));
          return _gate(context, work);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _gate(BuildContext context, Map<String, dynamic> work) {
    final isExplicit = work['content_rating'] == 'explicit';

    if (isExplicit && !_accessChecked) {
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
      return const Center(child: Text('This chapter is age-restricted (18+).'));
    }

    return _ChapterContent(work: work, chapterNum: widget.chapterNum);
  }
}

class _ChapterContent extends ConsumerWidget {
  final Map<String, dynamic> work;
  final int chapterNum;
  const _ChapterContent({required this.work, required this.chapterNum});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme  = Theme.of(context);
    final workId = work['id'] as String;
    final slug   = work['slug'] as String;

    return FutureBuilder<Map<String, dynamic>?>(
      future: ChaptersService().fetchChapter(workId, chapterNum),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final chapter = snapshot.data;
        if (chapter == null) {
          // Either doesn't exist, or stubbed beyond visibility boundary.
          return _stubNotice(context, work);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push('/work/$slug'),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text(work['title'] as String),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chapter $chapterNum'
                    '${chapter['title'] != null ? ': ${chapter['title']}' : ''}',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  if (chapter['author_note_pre'] != null) ...[
                    _authorNote(context, chapter['author_note_pre'] as String),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    chapter['content_text'] as String? ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
                  ),

                  if (chapter['author_note_post'] != null) ...[
                    const SizedBox(height: 24),
                    _authorNote(context, chapter['author_note_post'] as String),
                  ],

                  const SizedBox(height: 40),
                  _chapterNav(context, slug, chapterNum, work['chapter_count'] as int),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _authorNote(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
    );
  }

  Widget _chapterNav(BuildContext context, String slug, int current, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (current > 1)
          OutlinedButton.icon(
            onPressed: () => context.go('/work/$slug/chapter/${current - 1}'),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          )
        else
          const SizedBox.shrink(),
        if (current < total)
          FilledButton.icon(
            onPressed: () => context.go('/work/$slug/chapter/${current + 1}'),
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next Chapter'),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _stubNotice(BuildContext context, Map<String, dynamic> work) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'Want to keep reading?',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('This story continues exclusively on Amazon.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/work/${work['slug']}'),
              child: const Text('Back to Story Page'),
            ),
          ],
        ),
      ),
    );
  }
}
