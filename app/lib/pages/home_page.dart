// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/works_providers.dart';
import '../widgets/app_shell.dart';
import '../widgets/work_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingWorksProvider);
    final recent   = ref.watch(recentWorksProvider);

    return AppShell(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trendingWorksProvider);
          ref.invalidate(recentWorksProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            _heroBanner(context),
            const SizedBox(height: 32),
            _rail(context, 'Trending', trending),
            const SizedBox(height: 32),
            _rail(context, 'Recently Updated', recent),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _heroBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Write freely. Read deeply.',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(color: theme.colorScheme.onPrimary)),
          const SizedBox(height: 8),
          Text(
            'A fiction platform built for serialized stories — and the people who write them.',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.85)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              FilledButton(
                onPressed: () => context.push('/browse'),
                child: const Text('Start Reading'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => context.push('/write'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimary,
                  side: BorderSide(color: theme.colorScheme.onPrimary),
                ),
                child: const Text('Start Writing'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rail(
    BuildContext context,
    String title,
    AsyncValue<List<Map<String, dynamic>>> asyncWorks,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(title, style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: asyncWorks.when(
            data: (works) => works.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Nothing here yet.'),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: works.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, i) => WorkCard(work: works[i]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}
