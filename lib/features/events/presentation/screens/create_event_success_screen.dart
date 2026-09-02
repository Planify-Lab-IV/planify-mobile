import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/event.dart';
import '../controllers/event_draft_providers.dart';

class CreateEventSuccessScreen extends ConsumerWidget {
  final Event event;

  const CreateEventSuccessScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final draft = ref.watch(eventDraftProvider);

    final groupDisplayName = draft.isNewGroup
        ? (draft.newGroupName != null && draft.newGroupName!.isNotEmpty
              ? draft.newGroupName!
              : '-')
        : (draft.selectedGroupName != null &&
                  draft.selectedGroupName!.isNotEmpty
              ? draft.selectedGroupName!
              : event.groupId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.createEventTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 44,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  i18n.createEventSuccessTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  i18n.createEventSuccessSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: AppColors.outline),
                const SizedBox(height: AppSpacing.md),

                // Resumen del evento creado
                const SizedBox(height: AppSpacing.sm),
                _buildSummaryTile(
                  context,
                  label: i18n.eventNameLabel,
                  value: event.name,
                  valueKey: const Key('created_event_name'),
                  icon: Icons.celebration_outlined,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildSummaryTile(
                  context,
                  label: i18n.eventLocationLabel,
                  value: event.location,
                  valueKey: const Key('created_event_location'),
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildSummaryTile(
                  context,
                  label: i18n.assignedGroupLabel,
                  value: groupDisplayName,
                  valueKey: const Key('created_event_group'),
                  icon: Icons.groups_outlined,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Botón para volver al inicio
                ElevatedButton.icon(
                  key: const Key('back_to_home_button'),
                  onPressed: () {
                    ref.read(eventDraftProvider.notifier).reset();
                    ref.read(createEventNotifierProvider.notifier).resetState();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home_rounded),
                  label: Text(i18n.backToHomeButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(
    BuildContext context, {
    required String label,
    required String value,
    required Key valueKey,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

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
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              key: valueKey,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
