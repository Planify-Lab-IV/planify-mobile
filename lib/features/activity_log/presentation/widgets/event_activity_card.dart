import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/activity_entry.dart';
import '../activity_entry_description.dart';
import '../controllers/activity_log_providers.dart';
import '../controllers/event_activity_state.dart';
import 'activity_type_style.dart';

class EventActivityCard extends ConsumerWidget {
  final String eventId;

  const EventActivityCard({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(eventActivityNotifierProvider(eventId));
    final notifier = ref.read(eventActivityNotifierProvider(eventId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.activityLogSectionTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          key: const Key('event_activity_card'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: switch (state.loadStatus) {
              EventActivityLoadStatus.loading => _LoadingState(
                label: i18n.activityLoading,
              ),
              EventActivityLoadStatus.error => _FeedbackState(
                key: const Key('event_activity_error'),
                icon: Icons.error_outline_rounded,
                iconColor: theme.colorScheme.error,
                message: i18n.activityLoadError,
                action: TextButton(
                  key: const Key('event_activity_retry_button'),
                  onPressed: notifier.reload,
                  child: Text(i18n.retryButton),
                ),
              ),
              EventActivityLoadStatus.success when state.entries.isEmpty =>
                _FeedbackState(
                  key: const Key('event_activity_empty'),
                  icon: Icons.history_rounded,
                  iconColor: AppColors.onSurfaceVariant,
                  message: i18n.noActivityPlaceholder,
                ),
              EventActivityLoadStatus.success => _ActivityList(
                entries: state.entries,
              ),
            },
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  final String label;

  const _LoadingState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('event_activity_loading'),
      label: label,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _FeedbackState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String message;
  final Widget? action;

  const _FeedbackState({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.sm),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  final List<ActivityEntry> entries;

  const _ActivityList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          _ActivityRow(entry: entries[index]),
          if (index < entries.length - 1)
            const Divider(height: AppSpacing.lg, color: AppColors.outline),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityEntry entry;

  const _ActivityRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final style = activityTypeStyle(entry.type, theme.colorScheme);
    final createdAt = DateFormat.yMd(
      i18n.localeName,
    ).add_Hm().format(entry.createdAt.toLocal());

    return Row(
      key: Key('event_activity_row_${entry.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: Key('event_activity_icon_${entry.id}'),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: style.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(style.icon, color: style.color, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activityEntryDescription(entry, i18n),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                createdAt,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
