import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/event_participant.dart';
import '../../data/expenses_exceptions.dart';
import '../controllers/add_expense_context.dart';
import '../controllers/add_expense_notifier.dart';
import '../controllers/expenses_providers.dart';
import 'add_expense_form.dart';
import 'add_expense_submit_button.dart';

// Formulario para crear un gasto en el evento seleccionado.
class AddExpenseDialog extends ConsumerWidget {
  final String eventId;
  final List<EventParticipant> participants;

  const AddExpenseDialog({
    super.key,
    required this.eventId,
    required this.participants,
  });

  static Future<void> show(
    BuildContext context, {
    required String eventId,
    required List<EventParticipant> participants,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final successMessage = AppLocalizations.of(context)!.addExpenseSaveSuccess;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      // Keep the error and Retry above the modal barrier.
      builder: (_) => ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: AddExpenseDialog(
              eventId: eventId,
              participants: participants,
            ),
          ),
        ),
      ),
    );
    if (!context.mounted || saved != true) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: const Key('add_expense_success_snackbar'),
        content: Text(successMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveExpense(
    BuildContext context,
    AddExpenseNotifier notifier,
    AppLocalizations i18n,
  ) async {
    if (!context.mounted) return;
    final wasSaved = await notifier.submit();
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (!wasSaved) {
      final error = notifier.submissionError;
      if (error == null) return;
      final message = switch (error) {
        ExpenseValidationException() => i18n.addExpenseValidationError,
        ExpenseAuthenticationException() => i18n.addExpenseAuthenticationError,
        ExpenseForbiddenException() => i18n.addExpenseForbiddenError,
        ExpenseEventNotFoundException() => i18n.addExpenseNotFoundError,
        ExpenseEventUnavailableException() =>
          i18n.addExpenseEventUnavailableError,
        ExpensesClosedException() => i18n.addExpenseClosedError,
        NetworkExpenseException() => i18n.addExpenseNetworkError,
        _ => i18n.addExpenseSaveError,
      };
      messenger.showSnackBar(
        SnackBar(
          key: const Key('add_expense_error_snackbar'),
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: i18n.retryButton,
            onPressed: () => _saveExpense(context, notifier, i18n),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final draftContext = AddExpenseContext(
      eventId: eventId,
      participants: participants,
    );
    final state = ref.watch(addExpenseNotifierProvider(draftContext));
    final notifier = ref.read(
      addExpenseNotifierProvider(draftContext).notifier,
    );
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return PopScope(
      canPop: !state.isSaving,
      child: AnimatedPadding(
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
                              onPressed: state.isSaving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: FocusScope(
                          canRequestFocus: !state.isSaving,
                          child: AbsorbPointer(
                            absorbing: state.isSaving,
                            child: SingleChildScrollView(
                              key: const Key('add_expense_dialog_scroll_view'),
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: AddExpenseForm(
                                state: state,
                                notifier: notifier,
                                enabled: !state.isSaving,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: SizedBox(
                          width: double.infinity,
                          child: AddExpenseSubmitButton(
                            state: state,
                            onSubmit: () =>
                                _saveExpense(context, notifier, i18n),
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
      ),
    );
  }
}
