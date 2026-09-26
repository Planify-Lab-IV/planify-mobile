import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/event_participant.dart';
import '../controllers/add_expense_notifier.dart';
import '../controllers/expenses_providers.dart';
import 'expense_debtor_amounts.dart';
import 'expense_debtor_selector.dart';
import 'expense_header_fields.dart';
import 'expense_payer_amounts.dart';
import 'expense_payer_selector.dart';

// Panel transitorio para armar un gasto antes de que exista el envío HTTP.
class AddExpenseDialog extends ConsumerWidget {
  final List<EventParticipant> participants;

  const AddExpenseDialog({super.key, required this.participants});

  static Future<void> show(
    BuildContext context, {
    required List<EventParticipant> participants,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseDialog(participants: participants),
    );
  }

  Future<void> _saveExpense(
    BuildContext context,
    AddExpenseNotifier notifier,
    AppLocalizations i18n,
  ) async {
    final wasSaved = await notifier.save();
    if (!context.mounted || !wasSaved) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(i18n.addExpenseSaveSuccess),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(addExpenseNotifierProvider(participants));
    final notifier = ref.read(
      addExpenseNotifierProvider(participants).notifier,
    );
    final selectedPayerIds = {
      for (final payer in state.payerDrafts) payer.participantId,
    };
    final selectedDebtorIds = {
      for (final debtor in state.debtorDrafts) debtor.participantId,
    };
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final locale = Localizations.localeOf(context).toString();

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.sm,
                        AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              i18n.addExpenseDialogTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('add_expense_dialog_close_button'),
                            tooltip: i18n.addExpenseCloseTooltip,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const Key('add_expense_dialog_scroll_view'),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ExpenseHeaderFields(
                              initialDescription: state.description,
                              initialTotalAmount: state.totalAmountCents > 0
                                  ? formatCents(
                                      state.totalAmountCents,
                                      locale: locale,
                                    )
                                  : '',
                              onDescriptionChanged: notifier.setDescription,
                              onTotalAmountChanged: (amountCents) => notifier
                                  .setTotalAmountCents(amountCents ?? 0),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ExpensePayerSelector(
                              participants: state.participants,
                              selectedParticipantIds: selectedPayerIds,
                              onParticipantToggled: notifier.togglePayer,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ExpenseDebtorSelector(
                              participants: state.participants,
                              selectedParticipantIds: selectedDebtorIds,
                              onParticipantToggled: notifier.toggleDebtor,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ExpensePayerAmounts(
                              participants: state.participants,
                              payerDrafts: state.payerDrafts,
                              differenceCents: state.differenceCents,
                              onPayerAmountChanged:
                                  (participantId, amountCents) {
                                    if (amountCents != null) {
                                      notifier.setPayerAmount(
                                        participantId,
                                        amountCents,
                                      );
                                    }
                                  },
                              onSplitEvenly: notifier.splitPayersEvenly,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ExpenseDebtorAmounts(
                              participants: state.participants,
                              debtorDrafts: state.debtorDrafts,
                              differenceCents: state.debtorDifferenceCents,
                              onDebtorAmountChanged:
                                  (participantId, amountCents) {
                                    if (amountCents != null) {
                                      notifier.setDebtorAmount(
                                        participantId,
                                        amountCents,
                                      );
                                    }
                                  },
                              onSplitEvenly: notifier.splitDebtorsEvenly,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('add_expense_save_button'),
                          onPressed:
                              state.isReadyForSubmission && !state.isSaving
                              ? () => _saveExpense(context, notifier, i18n)
                              : null,
                          icon: state.isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            state.isSaving
                                ? i18n.addExpenseSaving
                                : i18n.addExpenseSave,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
