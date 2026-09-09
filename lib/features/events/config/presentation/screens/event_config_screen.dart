import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../attendance/widgets/attendance_response_selector.dart';
import '../../../../availability/presentation/controllers/availability_providers.dart';
import '../../../../availability/presentation/controllers/availability_state.dart';
import '../../../../availability/presentation/widgets/availability_grid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventConfigScreen extends ConsumerWidget {
  final String eventId;

  const EventConfigScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final availabilityState = ref.watch(availabilityNotifierProvider(eventId));
    final availabilityNotifier = ref.read(
      availabilityNotifierProvider(eventId).notifier,
    );

    ref.listen<AvailabilityState>(availabilityNotifierProvider(eventId), (
      previous,
      next,
    ) {
      if (previous?.saveStatus == next.saveStatus) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      if (next.saveStatus == AvailabilitySaveStatus.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(i18n.availabilitySaveSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.saveStatus == AvailabilitySaveStatus.error) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(i18n.availabilitySaveError),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.eventConfigTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AttendanceResponseSelector(eventId: eventId),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  i18n.availabilityTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  i18n.availabilitySubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (availabilityState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (availabilityState.hasLoadError)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          i18n.availabilityLoadError,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton(
                          onPressed: availabilityNotifier.load,
                          child: Text(i18n.retryButton),
                        ),
                      ],
                    ),
                  )
                else ...[
                  AvailabilityGrid(
                    selectedSlots: availabilityState.selectedSlots,
                    onToggleSlot: availabilityNotifier.toggleSlot,
                    onMarkSlot: availabilityNotifier.markSlot,
                    isEnabled: !availabilityState.isSaving,
                    dayLabels: [
                      i18n.availabilityMondayShort,
                      i18n.availabilityTuesdayShort,
                      i18n.availabilityWednesdayShort,
                      i18n.availabilityThursdayShort,
                      i18n.availabilityFridayShort,
                      i18n.availabilitySaturdayShort,
                      i18n.availabilitySundayShort,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    key: const Key('availability_save_button'),
                    onPressed: availabilityState.isSaving
                        ? null
                        : availabilityNotifier.save,
                    child: availabilityState.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(i18n.availabilitySave),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
