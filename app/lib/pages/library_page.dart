// lib/pages/library_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/serials_db.dart';
import '../widgets/app_shell.dart';
import '../widgets/work_card.dart';

const _listLabels = {
  'reading':     'Currently Reading',
  'tbr':         'To Be Read',
  'read':        'Read',
  'recommended': 'Recommended',
};

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const AppShell(
        body: Center(child: Text('Sign in to view your library.')),
      );
    }

    return AppShell(
      body: DefaultTabController(
        length: _listLabels.length,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Currently Reading'),
                Tab(text: 'To Be Read'),
                Tab(text: 'Read'),
                Tab(text: 'Recommended'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: _listLabels.keys
                    .map((type) => _ListView(listType: type, userId: user.id))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  final String listType;
  final String userId;
  const _ListView({required this.listType, required this.userId});

  Future<List<Map<String, dynamic>>> _fetch() async {
    // user_work_lists has no FK-based embed to works_full across schemas,
    // so resolve work IDs first, then fetch full rows from works_full.
    final listRows = await SerialsDb.db
        .from('user_work_lists')
        .select('work_id')
        .eq('user_id', userId)
        .eq('list_type', listType)
        .order('added_at', ascending: false);

    final workIds = List<String>.from(
        (listRows as List).map((r) => r['work_id'] as String));
    if (workIds.isEmpty) return [];

    final works = await SerialsDb.db
        .from('works_full')
        .select('*')
        .inFilter('id', workIds);
    return List<Map<String, dynamic>>.from(works as List);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final works = snapshot.data!;
        if (works.isEmpty) {
          return Center(child: Text('Nothing in "${_listLabels[listType]}" yet.'));
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: works.map((w) => WorkCard(work: w)).toList(),
          ),
        );
      },
    );
  }
}
