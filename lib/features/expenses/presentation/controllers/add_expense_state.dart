import '../../../events/domain/event_participant.dart';
import '../../domain/expense_debtor_draft.dart';
import '../../domain/expense_payer_draft.dart';

// Foto actual del formulario de gastos
class AddExpenseState {
  final List<EventParticipant> participants;
  final String description;
  final int totalAmountCents;
  final List<ExpensePayerDraft> payerDrafts;
  final int payersTotalCents;
  final int differenceCents;
  final List<ExpenseDebtorDraft> debtorDrafts;
  final int debtorsTotalCents;
  final int debtorDifferenceCents;

  AddExpenseState({
    required List<EventParticipant> participants,
    this.description = '',
    this.totalAmountCents = 0,
    List<ExpensePayerDraft> payerDrafts = const [],
    this.payersTotalCents = 0,
    this.differenceCents = 0,
    List<ExpenseDebtorDraft> debtorDrafts = const [],
    this.debtorsTotalCents = 0,
    this.debtorDifferenceCents = 0,
  }) : participants = List<EventParticipant>.unmodifiable(participants),
       payerDrafts = List<ExpensePayerDraft>.unmodifiable(payerDrafts),
       debtorDrafts = List<ExpenseDebtorDraft>.unmodifiable(debtorDrafts);

  bool get hasDescription => description.trim().isNotEmpty;
  bool get hasValidTotal => totalAmountCents > 0;
  bool get hasPayers => payerDrafts.isNotEmpty;
  bool get hasBalancedPayers => hasPayers && differenceCents == 0;
  bool get hasDebtors => debtorDrafts.isNotEmpty;
  bool get hasBalancedDebtors => hasDebtors && debtorDifferenceCents == 0;

  bool get isReadyForSubmission =>
      hasDescription &&
      hasValidTotal &&
      hasBalancedPayers &&
      hasBalancedDebtors;

  bool isPayerSelected(String participantId) {
    return payerDrafts.any((payer) => payer.participantId == participantId);
  }

  bool isDebtorSelected(String participantId) {
    return debtorDrafts.any((debtor) => debtor.participantId == participantId);
  }
}
