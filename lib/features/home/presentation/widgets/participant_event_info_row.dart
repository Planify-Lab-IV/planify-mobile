import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../events/detail/controllers/events_providers.dart';

class ParticipantEventInfoRow extends ConsumerWidget {
  final String eventId;

  const ParticipantEventInfoRow({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final eventState = ref.watch(eventDetailNotifierProvider(eventId));

    final String eventDisplayName;
    if (eventState.isLoading) {
      eventDisplayName = i18n.loadingEvent;
    } else if (eventState.event != null) {
      eventDisplayName = eventState.event!.name;
    } else {
      eventDisplayName = i18n.eventNotFound;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${i18n.eventLabel}: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              eventDisplayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
