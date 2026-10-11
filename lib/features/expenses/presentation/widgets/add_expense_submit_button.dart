import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/add_expense_state.dart';

class AddExpenseSubmitButton extends StatelessWidget {
  final AddExpenseState state;
  final VoidCallback onSubmit;

  const AddExpenseSubmitButton({
    super.key,
    required this.state,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    return FilledButton.icon(
      key: const Key('add_expense_save_button'),
      onPressed:
          state.isReadyForSubmission &&
              !state.isSaving &&
              state.saveStatus != ExpenseSaveStatus.success
          ? onSubmit
          : null,
      icon: state.isSaving
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : const Icon(Icons.save_rounded),
      label: Text(state.isSaving ? i18n.addExpenseSaving : i18n.addExpenseSave),
    );
  }
}
