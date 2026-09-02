import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/events_providers.dart';
import '../widgets/cancel_event_dialog.dart';
import '../widgets/event_header_card.dart';
import '../widgets/event_quick_actions_card.dart';
import '../widgets/event_section_placeholder_card.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  Future<void> _confirmAndCancel(BuildContext context, WidgetRef ref) async {
    final i18n = AppLocalizations.of(context)!;
    final confirmed = await CancelEventDialog.show(context);
    if (!context.mounted || confirmed != true) return;

    final notifier = ref.read(eventDetailNotifierProvider(eventId).notifier);
    final success = await notifier.cancelEvent();
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          key: const Key('cancel_event_success_snackbar'),
          content: Text(i18n.cancelEventSuccess),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          key: const Key('cancel_event_error_snackbar'),
          content: Text(i18n.cancelEventError),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: i18n.retryButton,
            textColor: Colors.white,
            onPressed: () => _confirmAndCancel(context, ref),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(eventDetailNotifierProvider(eventId));
    final notifier = ref.read(eventDetailNotifierProvider(eventId).notifier);

    final event = state.event;
    final canCancel = notifier.canCancelEvent;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.eventDetailTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (canCancel)
            PopupMenuButton<String>(
              key: const Key('event_actions_menu_button'),
              tooltip: i18n.eventActionsTooltip,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'cancel') {
                  _confirmAndCancel(context, ref);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  key: const Key('cancel_event_menu_item'),
                  value: 'cancel',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cancel_outlined,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        i18n.cancelEventAction,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.hasLoadError && event == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      i18n.eventNotFound,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      key: const Key('retry_load_event_button'),
                      onPressed: () => notifier.loadEvent(),
                      child: Text(i18n.retryButton),
                    ),
                  ],
                ),
              ),
            );
          }

          if (event == null) {
            return Center(child: Text(i18n.eventNotFound));
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (event.isCancelled) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                i18n.eventCancelledNotice,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    EventHeaderCard(event: event),
                    const SizedBox(height: AppSpacing.lg),
                    EventQuickActionsCard(isCancelled: event.isCancelled),
                    const SizedBox(height: AppSpacing.lg),
                    EventSectionPlaceholderCard(
                      cardKey: const Key('tasks_placeholder_card'),
                      title: i18n.tasksSectionTitle,
                      placeholderText: i18n.noTasksPlaceholder,
                      icon: Icons.checklist_rounded,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    EventSectionPlaceholderCard(
                      cardKey: const Key('activity_placeholder_card'),
                      title: i18n.activityLogSectionTitle,
                      placeholderText: i18n.noActivityPlaceholder,
                      icon: Icons.history_rounded,
                    ),
                    if (canCancel) ...[
                      const SizedBox(height: AppSpacing.xl),
                      OutlinedButton.icon(
                        key: const Key('cancel_event_button'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          side: const BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                        ),
                        onPressed: state.isCancelling
                            ? null
                            : () => _confirmAndCancel(context, ref),
                        icon: state.isCancelling
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.error,
                                ),
                              )
                            : const Icon(Icons.cancel_outlined),
                        label: Text(
                          state.isCancelling
                              ? i18n.cancellingEvent
                              : i18n.cancelEventAction,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
