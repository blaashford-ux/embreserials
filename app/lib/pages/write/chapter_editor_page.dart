// lib/pages/write/chapter_editor_page.dart
//
// Uses flutter_quill (MVP editor — see Phase 1 decision to defer TipTap).
// Autosaves every 30s while the document is dirty, plus a manual Save button.
// Word count recalculates live; the writing pace panel updates after each save
// since pace is computed from word_count_total on the work record.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/works_providers.dart';
import '../../services/chapters_service.dart';
import '../../services/writing_stats_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/writing_pace_panel.dart';

class ChapterEditorPage extends ConsumerStatefulWidget {
  final String workId;
  final String chapterId;
  const ChapterEditorPage({super.key, required this.workId, required this.chapterId});

  @override
  ConsumerState<ChapterEditorPage> createState() => _ChapterEditorPageState();
}

class _ChapterEditorPageState extends ConsumerState<ChapterEditorPage> {
  late quill.QuillController _controller;
  late TextEditingController _titleController;
  late TextEditingController _notePreController;
  late TextEditingController _notePostController;

  Timer?   _autosaveTimer;
  bool     _dirty   = false;
  bool     _saving  = false;
  bool     _loading = true;
  int      _wordCount = 0;
  DateTime? _lastSaved;

  Map<String, dynamic>? _chapter;

  @override
  void initState() {
    super.initState();
    _controller         = quill.QuillController.basic();
    _titleController     = TextEditingController();
    _notePreController   = TextEditingController();
    _notePostController  = TextEditingController();
    _load();

    _autosaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_dirty) _save(showSnack: false);
    });
  }

  Future<void> _load() async {
    final chapter = await ChaptersService().fetchChapterById(widget.chapterId);
    if (chapter == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final contentJson = chapter['content_json'];
    final document = (contentJson is List && contentJson.isNotEmpty)
        ? quill.Document.fromJson(contentJson)
        : quill.Document();

    _controller = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _controller.document.changes.listen((_) => _onTextChanged());

    _titleController.text    = chapter['title'] as String? ?? '';
    _notePreController.text  = chapter['author_note_pre'] as String? ?? '';
    _notePostController.text = chapter['author_note_post'] as String? ?? '';

    if (mounted) {
      setState(() {
        _chapter   = chapter;
        _wordCount = chapter['word_count'] as int? ?? 0;
        _loading   = false;
      });
    }
  }

  void _onTextChanged() {
    final text = _controller.document.toPlainText();
    final count = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;
    setState(() {
      _wordCount = count;
      _dirty     = true;
    });
  }

  Future<void> _save({bool showSnack = true}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final delta = _controller.document.toDelta().toJson();
      final text  = _controller.document.toPlainText();

      await ChaptersService().saveChapter(
        chapterId:   widget.chapterId,
        contentJson: delta,
        contentText: text,
        wordCount:   _wordCount,
        title:           _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        authorNotePre:   _notePreController.text,
        authorNotePost:  _notePostController.text,
      );

      ref.invalidate(allChaptersProvider(widget.workId));
      ref.invalidate(myWorksProvider);

      if (mounted) {
        setState(() {
          _dirty      = false;
          _lastSaved  = DateTime.now();
        });
        if (showSnack) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Saved')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish() async {
    await _save(showSnack: false);
    await ChaptersService().publishChapter(widget.chapterId);
    ref.invalidate(allChaptersProvider(widget.workId));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chapter published')));
    }
  }

  @override
  void dispose() {
    if (_dirty) _save(showSnack: false);
    _autosaveTimer?.cancel();
    _titleController.dispose();
    _notePreController.dispose();
    _notePostController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppShell(body: Center(child: CircularProgressIndicator()));
    }
    if (_chapter == null) {
      return const AppShell(body: Center(child: Text('Chapter not found.')));
    }

    return AppShell(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _editorColumn()),
          SizedBox(
            width: 320,
            child: _sidebarColumn(),
          ),
        ],
      ),
    );
  }

  Widget _editorColumn() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.push('/write/${widget.workId}'),
              ),
              Expanded(
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Chapter title (optional)',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                  onChanged: (_) => setState(() => _dirty = true),
                ),
              ),
            ],
          ),
        ),
        quill.QuillSimpleToolbar(controller: _controller),
        const Divider(height: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: quill.QuillEditor.basic(controller: _controller),
          ),
        ),
        _statusBar(),
      ],
    );
  }

  Widget _statusBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$_wordCount words'
            '${_dirty ? ' · Unsaved changes' : _lastSaved != null ? ' · Saved' : ''}',
            style: theme.textTheme.bodySmall,
          ),
          Row(
            children: [
              TextButton(
                onPressed: _saving ? null : () => _save(),
                child: const Text('Save Draft'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saving ? null : _publish,
                child: Text(
                    _chapter!['status'] == 'published' ? 'Republish' : 'Publish'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sidebarColumn() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Author Notes', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _notePreController,
              decoration: const InputDecoration(
                labelText: 'Note before chapter',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (_) => setState(() => _dirty = true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notePostController,
              decoration: const InputDecoration(
                labelText: 'Note after chapter',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (_) => setState(() => _dirty = true),
            ),
            const SizedBox(height: 24),
            Text('Pace', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            FutureBuilder(
              future: _fetchPace(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return WritingPacePanel(pace: snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<WritingPace> _fetchPace() async {
    final myWorks = await ref.read(myWorksProvider.future);
    final work = myWorks.firstWhere(
      (w) => w['id'] == widget.workId,
      orElse: () => <String, dynamic>{},
    );
    return WritingStatsService().computePace(
      authorId:     work['author_id'] as String? ?? '',
      currentWords: work['word_count_total'] as int? ?? 0,
      targetWords:  work['target_word_count'] as int?,
      targetDate:   work['target_completion_date'] != null
          ? DateTime.parse(work['target_completion_date'] as String)
          : null,
    );
  }
}
