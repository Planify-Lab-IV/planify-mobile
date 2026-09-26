import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/event_participant.dart';

// Presenta los participantes del evento para seleccionar quién debe el gasto
class ExpenseDebtorSelector extends StatelessWidget {
  final List<EventParticipant> participants;
  final Set<String> selectedParticipantIds;
  final ValueChanged<String> onParticipantToggled;

  const ExpenseDebtorSelector({
    super.key,
    required this.participants,
    required this.selectedParticipantIds,
    required this.onParticipantToggled,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.addExpenseDebtorsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          i18n.addExpenseDebtorsSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final participant in participants)
          CheckboxListTile(
            key: Key('expense_debtor_selector_${participant.id}'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: selectedParticipantIds.contains(participant.id),
            title: Text(
              participant.username,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            onChanged: (_) => onParticipantToggled(participant.id),
          ),
      ],
    );
  }
}
