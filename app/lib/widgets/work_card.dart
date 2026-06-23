// lib/widgets/work_card.dart
//
// Reusable card for any grid of works (home rails, browse, author page).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'cover_image.dart';

class WorkCard extends StatelessWidget {
  final Map<String, dynamic> work;
  final double width;

  const WorkCard({super.key, required this.work, this.width = 160});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = work['title'] as String? ?? '';
    final author = work['author_display_name'] as String? ?? 'Unknown';
    final rating = work['content_rating'] as String? ?? 'general';

    return InkWell(
      onTap: () => context.push('/work/${work['slug']}'),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CoverImage(coverFilename: work['cover_url'] as String?, width: width),
                if (rating == 'explicit' || rating == 'mature')
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rating == 'explicit' ? '18+' : 'M',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: theme.textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              author,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
