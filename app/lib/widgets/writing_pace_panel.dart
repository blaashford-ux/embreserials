// lib/widgets/writing_pace_panel.dart
//
// Author-only panel shown in the chapter editor / work settings.
// Displays current vs target, required pace, actual pace, on-track status,
// and estimated completion at current pace.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/writing_stats_service.dart';

class WritingPacePanel extends StatelessWidget {
  final WritingPace pace;

  const WritingPacePanel({super.key, required this.pace});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt   = NumberFormat('#,###');

    if (pace.targetWords == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Set a target word count in Work Settings to track your pace.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final percent = (pace.currentWords / pace.targetWords!).clamp(0.0, 1.0);
    final statusColor = pace.onTrack == null
        ? theme.colorScheme.onSurfaceVariant
        : pace.onTrack!
            ? Colors.green.shade700
            : Colors.orange.shade800;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${fmt.format(pace.currentWords)} / ${fmt.format(pace.targetWords)} words',
                  style: theme.textTheme.titleSmall,
                ),
                Text('${(percent * 100).round()}%', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.secondary),
              ),
            ),
            const SizedBox(height: 16),

            if (pace.targetDate != null) ...[
              _row(theme, 'Target date',
                  DateFormat.yMMMd().format(pace.targetDate!)),
              _row(theme, 'Required pace',
                  '${pace.requiredPace?.round() ?? '--'} words/day'),
            ],
            _row(
              theme,
              'Your pace (30d avg)',
              '${pace.actualAvgPace30d.round()} words/day',
              valueColor: statusColor,
              trailing: pace.onTrack == null
                  ? null
                  : Icon(
                      pace.onTrack! ? Icons.check_circle : Icons.warning_amber,
                      size: 16,
                      color: statusColor,
                    ),
            ),
            if (pace.estimatedCompletion != null)
              _row(
                theme,
                'Est. completion at current pace',
                DateFormat.yMMMd().format(pace.estimatedCompletion!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value,
      {Color? valueColor, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Row(
            children: [
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing],
            ],
          ),
        ],
      ),
    );
  }
}
