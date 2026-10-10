import 'package:flutter/material.dart';
import '../../../../core/formatting/money_formatter.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/add_expense_notifier.dart';
import '../controllers/add_expense_state.dart';
import 'expense_debtor_amounts.dart';
import 'expense_debtor_selector.dart';
import 'expense_header_fields.dart';
import 'expense_payer_amounts.dart';
import 'expense_payer_selector.dart';

/// Composes inputs; all draft operations remain in the notifier.
class AddExpenseForm extends StatelessWidget {
  final AddExpenseState state;
  final AddExpenseNotifier notifier;
  final bool enabled;

  const AddExpenseForm({
    super.key,
    required this.state,
    required this.notifier,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpenseHeaderFields(
          initialDescription: state.description,
          initialTotalAmount: state.totalAmountCents > 0
              ? formatCents(state.totalAmountCents, locale: locale)
              : '',
          enabled: enabled,
          onDescriptionChanged: notifier.setDescription,
          onTotalAmountChanged: (amount) =>
              notifier.setTotalAmountCents(amount ?? 0),
        ),
        const SizedBox(height: AppSpacing.lg),
        ExpensePayerSelector(
          participants: state.participants,
          selectedParticipantIds: {
            for (final payer in state.payerDrafts) payer.participantId,
          },
          onParticipantToggled: notifier.togglePayer,
        ),
        const SizedBox(height: AppSpacing.lg),
        ExpenseDebtorSelector(
          participants: state.participants,
          selectedParticipantIds: {
            for (final debtor in state.debtorDrafts) debtor.participantId,
          },
          onParticipantToggled: notifier.toggleDebtor,
        ),
        const SizedBox(height: AppSpacing.lg),
        ExpensePayerAmounts(
          participants: state.participants,
          payerDrafts: state.payerDrafts,
          differenceCents: state.differenceCents,
          enabled: enabled,
          onPayerAmountChanged: (id, amount) =>
              notifier.setPayerAmount(id, amount ?? 0),
          onSplitEvenly: notifier.splitPayersEvenly,
        ),
        const SizedBox(height: AppSpacing.lg),
        ExpenseDebtorAmounts(
          participants: state.participants,
          debtorDrafts: state.debtorDrafts,
          differenceCents: state.debtorDifferenceCents,
          enabled: enabled,
          onDebtorAmountChanged: (id, amount) =>
              notifier.setDebtorAmount(id, amount ?? 0),
          onSplitEvenly: notifier.splitDebtorsEvenly,
        ),
      ],
    );
  }
}
