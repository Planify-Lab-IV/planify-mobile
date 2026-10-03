import 'expense_debtor_draft.dart';
import 'expense_payer_draft.dart';

/// A persisted expense; identity and creator are assigned by the backend.
class Expense {
  final String id;
  final String eventId;
  final String description;
  final int totalAmountCents;
  final String createdByParticipantId;
  final DateTime createdAt;
  final List<ExpensePayerDraft> payers;
  final List<ExpenseDebtorDraft> debtors;

  Expense({
    required this.id,
    required this.eventId,
    required this.description,
    required this.totalAmountCents,
    required this.createdByParticipantId,
    required this.createdAt,
    required List<ExpensePayerDraft> payers,
    required List<ExpenseDebtorDraft> debtors,
  }) : payers = List.unmodifiable(payers),
       debtors = List.unmodifiable(debtors);
}
