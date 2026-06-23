// lib/pages/author_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/serials_db.dart';
import '../providers/works_providers.dart';
import '../widgets/app_shell.dart';
import '../widgets/work_card.dart';

/// Author profiles are looked up by display_name (URL-friendly, unique enough
/// for Phase 1). If display names collide in practice, a slug column can be
/// added to author_profiles later without changing this page's shape.
class AuthorPage extends ConsumerWidget {
  final String username;
  const AuthorPage({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShell(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchProfile(username),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('Author not found.'));
          }
          return _AuthorDetail(profile: profile);
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchProfile(String displayName) async {
    final res = await SerialsDb.db
        .from('author_profiles')
        .select('*')
        .eq('display_name', displayName)
        .maybeSingle();
    return res as Map<String, dynamic>?;
  }
}

class _AuthorDetail extends ConsumerWidget {
  final Map<String, dynamic> profile;
  const _AuthorDetail({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme  = Theme.of(context);
    final fmt    = NumberFormat('#,###');
    final userId = profile['user_id'] as String;
    final works  = ref.watch(worksByAuthorProvider(userId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: profile['avatar_url'] != null
                      ? NetworkImage(profile['avatar_url'] as String)
                      : null,
                  child: profile['avatar_url'] == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile['display_name'] as String? ?? 'Unknown Author',
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${profile['total_works']} works · '
                      '${fmt.format(profile['total_words'])} words written',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            if (profile['bio'] != null) ...[
              const SizedBox(height: 20),
              Text(profile['bio'] as String, style: theme.textTheme.bodyLarge),
            ],
            const SizedBox(height: 32),
            Text('Works', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            works.when(
              data: (list) => list.isEmpty
                  ? const Text('No published works yet.')
                  : Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: list.map((w) => WorkCard(work: w)).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
