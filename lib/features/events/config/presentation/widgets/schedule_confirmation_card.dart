import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_localizations.dart';
import '../controllers/schedule_confirmation_providers.dart';
import '../controllers/schedule_confirmation_state.dart';

class ScheduleConfirmationCard extends ConsumerStatefulWidget {
  final String eventId;
  final DateTime? initialStartDateTime;
  final Future<void> Function() onConfirmationSucceeded;

  const ScheduleConfirmationCard({
    super.key,
    required this.eventId,
    this.initialStartDateTime,
    required this.onConfirmationSucceeded,
  });

  @override
  ConsumerState<ScheduleConfirmationCard> createState() =>
      _ScheduleConfirmationCardState();
}

class _ScheduleConfirmationCardState
    extends ConsumerState<ScheduleConfirmationCard> {
  @override
  void initState() {
    super.initState();
    ref
        .read(scheduleConfirmationNotifierProvider(widget.eventId).notifier)
        .setInitialStartDateTime(widget.initialStartDateTime);
  }

  Future<void> _selectDate() async {
    final state = ref.read(scheduleConfirmationNotifierProvider(widget.eventId));
    final now = DateUtils.dateOnly(DateTime.now());
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: state.selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (!mounted || selectedDate == null) return;

    ref
        .read(scheduleConfirmationNotifierProvider(widget.eventId).notifier)
        .selectDate(selectedDate);
  }

  Future<void> _selectTime() async {
    final state = ref.read(scheduleConfirmationNotifierProvider(widget.eventId));
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: state.selectedTime ?? TimeOfDay.now(),
    );
    if (!mounted || selectedTime == null) return;

    ref
        .read(scheduleConfirmationNotifierProvider(widget.eventId).notifier)
        .selectTime(selectedTime);
  }

  Future<void> _confirmSchedule() async {
    final success = await ref
        .read(scheduleConfirmationNotifierProvider(widget.eventId).notifier)
        .confirmSchedule();
    if (!mounted || !success) return;

    await widget.onConfirmationSucceeded();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(scheduleConfirmationNotifierProvider(widget.eventId));

    return Card.outlined(
      key: const Key('schedule_confirmation_card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              key: const Key('schedule_select_date_button'),
              onPressed: state.isConfirming ? null : _selectDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                state.selectedDate == null
                    ? i18n.scheduleSelectDate
                    : MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(state.selectedDate!),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              key: const Key('schedule_select_time_button'),
              onPressed: state.isConfirming ? null : _selectTime,
              icon: const Icon(Icons.access_time_outlined),
              label: Text(
                state.selectedTime == null
                    ? i18n.scheduleSelectTime
                    : state.selectedTime!.format(context),
              ),
            ),
            if (state.confirmationFailed) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _failureMessage(i18n, state.failure),
                key: const Key('schedule_confirmation_error_message'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              key: const Key('schedule_confirm_button'),
              onPressed: state.canConfirm ? _confirmSchedule : null,
              child: state.isConfirming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(i18n.scheduleConfirm),
            ),
          ],
        ),
      ),
    );
  }

  String _failureMessage(
    AppLocalizations i18n,
    ScheduleConfirmationFailure? failure,
  ) {
    return switch (failure) {
      ScheduleConfirmationFailure.validation =>
        i18n.scheduleConfirmationValidationError,
      ScheduleConfirmationFailure.authorization =>
        i18n.scheduleConfirmationAuthorizationError,
      ScheduleConfirmationFailure.notFound =>
        i18n.scheduleConfirmationNotFoundError,
      ScheduleConfirmationFailure.network =>
        i18n.scheduleConfirmationNetworkError,
      _ => i18n.scheduleConfirmationGenericError,
    };
  }
}
