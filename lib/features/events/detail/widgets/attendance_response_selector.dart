import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/attendance_status.dart';
import '../controllers/events_providers.dart';

class AttendanceResponseSelector extends ConsumerWidget {
  final String eventId;
  final String participantId;

  const AttendanceResponseSelector({
    super.key,
    required this.eventId,
    required this.participantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final key = (eventId: eventId, participantId: participantId);
    final state = ref.watch(attendanceNotifierProvider(key));
    final notifier = ref.read(attendanceNotifierProvider(key).notifier);

    return Card.outlined(
      key: const Key('attendance_response_selector'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(i18n.attendanceTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _statusLabel(i18n, state.status),
              key: const Key('attendance_status_label'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _statusColor(state.status),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.isLoading)
              const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _AttendanceButton(
                      key: const Key('attendance_confirm_button'),
                      label: i18n.attendanceGoing,
                      color: AppColors.success,
                      foregroundColor: AppColors.onSuccess,
                      isSelected: state.status == AttendanceStatus.confirmed,
                      isSaving: state.isSaving,
                      onPressed: () =>
                          notifier.respond(AttendanceStatus.confirmed),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _AttendanceButton(
                      key: const Key('attendance_reject_button'),
                      label: i18n.attendanceNotGoing,
                      color: AppColors.danger,
                      foregroundColor: AppColors.onDanger,
                      isSelected: state.status == AttendanceStatus.rejected,
                      isSaving: state.isSaving,
                      onPressed: () =>
                          notifier.respond(AttendanceStatus.rejected),
                    ),
                  ),
                ],
              ),
            if (state.hasError) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                i18n.attendanceUpdateError,
                key: const Key('attendance_error_message'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations i18n, AttendanceStatus? status) {
    return switch (status) {
      AttendanceStatus.confirmed => i18n.attendanceConfirmed,
      AttendanceStatus.rejected => i18n.attendanceRejected,
      null => i18n.attendancePending,
    };
  }

  Color _statusColor(AttendanceStatus? status) {
    return switch (status) {
      AttendanceStatus.confirmed => AppColors.success,
      AttendanceStatus.rejected => AppColors.danger,
      null => AppColors.onSurfaceVariant,
    };
  }
}

class _AttendanceButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color foregroundColor;
  final bool isSelected;
  final bool isSaving;
  final VoidCallback onPressed;

  const _AttendanceButton({
    super.key,
    required this.label,
    required this.color,
    required this.foregroundColor,
    required this.isSelected,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return FilledButton(
        onPressed: isSaving ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
        child: Text(label),
      );
    }

    return OutlinedButton(
      onPressed: isSaving ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      child: Text(label),
    );
  }
}
