import 'expense_debtor_draft.dart';
import 'expense_payer_draft.dart';

/// Snapshot of the values confirmed by the user, all expressed in cents.
class NewExpense {
  final String description;
  final int totalAmountCents;
  final List<ExpensePayerDraft> payers;
  final List<ExpenseDebtorDraft> debtors;

  NewExpense({
    required this.description,
    required this.totalAmountCents,
    required List<ExpensePayerDraft> payers,
    required List<ExpenseDebtorDraft> debtors,
  }) : payers = List.unmodifiable(payers),
       debtors = List.unmodifiable(debtors);
}
