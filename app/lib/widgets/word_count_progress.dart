// lib/widgets/word_count_progress.dart
//
// Public-facing word count vs target progress bar, shown on the work page.
// Only rendered when the work has show_target_publicly = true AND a
// target_word_count set. The optional target date is its own opt-in flag.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WordCountProgress extends StatelessWidget {
  final int      currentWords;
  final int?     targetWords;
  final DateTime? targetDate;
  final bool     showTargetDate;

  const WordCountProgress({
    super.key,
    required this.currentWords,
    required this.targetWords,
    required this.targetDate,
    required this.showTargetDate,
  });

  @override
  Widget build(BuildContext context) {
    if (targetWords == null || targetWords! <= 0) {
      return const SizedBox.shrink();
    }

    final theme   = Theme.of(context);
    final percent = (currentWords / targetWords!).clamp(0.0, 1.0);
    final fmt     = NumberFormat('#,###');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Work in Progress',
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text('${(percent * 100).round()}%',
                style: theme.textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.secondary),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${fmt.format(currentWords)} / ${fmt.format(targetWords)} words',
          style: theme.textTheme.bodySmall,
        ),
        if (showTargetDate && targetDate != null) ...[
          const SizedBox(height: 2),
          Text(
            'Target: ${DateFormat.yMMMd().format(targetDate!)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
