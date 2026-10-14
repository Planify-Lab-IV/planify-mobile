import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/unread_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../activity_log/presentation/controllers/activity_log_providers.dart';
import '../../../events/detail/screens/event_detail_screen.dart';
import '../../domain/group_overview.dart';

class GroupEventTile extends ConsumerWidget {
  final GroupEventSummary event;

  const GroupEventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(unreadCountsProvider).asData?.value;
    final theme = Theme.of(context);
    final i18n = AppLocalizations.of(context)!;
    final date = event.startDateTime;
    final dateText = date == null
        ? i18n.groupsDateTbd
        : DateFormat.yMMMd(i18n.localeName).add_Hm().format(date);
    final confirmed = event.status.isConfirmed;
    final statusColor = confirmed
        ? AppColors.success
        : theme.colorScheme.primary;

    return Card(
      key: Key('group_event_tile_${event.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EventDetailScreen(eventId: event.id),
            ),
          );
          if (context.mounted) ref.invalidate(unreadCountsProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (counts != null && counts.forEvent(event.id) > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    UnreadBadge(
                      key: Key('event_unread_badge_${event.id}'),
                      count: counts.forEvent(event.id),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                dateText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      event.location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  confirmed
                      ? i18n.groupsEventConfirmed
                      : i18n.groupsEventActive,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
