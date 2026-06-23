// lib/pages/write/write_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/works_providers.dart';
import '../../services/works_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/cover_image.dart';

class WriteDashboardPage extends ConsumerWidget {
  const WriteDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worksAsync = ref.watch(myWorksProvider);

    return AppShell(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Works', style: Theme.of(context).textTheme.headlineMedium),
                FilledButton.icon(
                  onPressed: () => _createWork(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('New Work'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: worksAsync.when(
                data: (works) => works.isEmpty
                    ? _emptyState(context, ref)
                    : ListView.separated(
                        itemCount: works.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _WorkRow(work: works[i]),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_note, size: 48),
          const SizedBox(height: 12),
          const Text('You haven\'t started a work yet.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _createWork(context, ref),
            child: const Text('Start Your First Work'),
          ),
        ],
      ),
    );
  }

  Future<void> _createWork(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Work'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;

    final work = await WorksService().createWork(title: title);
    ref.invalidate(myWorksProvider);
    if (context.mounted) {
      context.push('/write/${work['id']}');
    }
  }
}

class _WorkRow extends StatelessWidget {
  final Map<String, dynamic> work;
  const _WorkRow({required this.work});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt   = NumberFormat('#,###');

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CoverImage(
          coverFilename: work['cover_url'] as String?,
          width: 56,
        ),
        title: Text(work['title'] as String, style: theme.textTheme.titleMedium),
        subtitle: Text(
          '${_statusLabel(work['status'] as String)} · '
          '${fmt.format(work['word_count_total'])} words · '
          '${work['chapter_count']} chapters',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/write/${work['id']}'),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft':     return 'Draft';
      case 'ongoing':   return 'Ongoing';
      case 'completed': return 'Completed';
      case 'hiatus':    return 'On Hiatus';
      case 'stub':      return 'Stubbed';
      default:          return status;
    }
  }
}
