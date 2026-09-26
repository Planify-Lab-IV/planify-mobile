import '../../../events/domain/event_participant.dart';
import '../../domain/expense_payer_draft.dart';

enum ExpenseSaveStatus { idle, saving, success }

// Foto actual del formulario de gastos
class AddExpenseState {
  final List<EventParticipant> participants;
  final String description;
  final int totalAmountCents;
  final List<ExpensePayerDraft> payerDrafts;
  final int payersTotalCents;
  final int differenceCents;
  final ExpenseSaveStatus saveStatus;

  AddExpenseState({
    required List<EventParticipant> participants,
    this.description = '',
    this.totalAmountCents = 0,
    List<ExpensePayerDraft> payerDrafts = const [],
    this.payersTotalCents = 0,
    this.differenceCents = 0,
    this.saveStatus = ExpenseSaveStatus.idle,
  }) : participants = List<EventParticipant>.unmodifiable(participants),
       payerDrafts = List<ExpensePayerDraft>.unmodifiable(payerDrafts);

  bool get hasDescription => description.trim().isNotEmpty;
  bool get hasValidTotal => totalAmountCents > 0;
  bool get hasPayers => payerDrafts.isNotEmpty;
  bool get hasBalancedPayers => hasPayers && differenceCents == 0;

  bool get isReadyForSubmission =>
      hasDescription && hasValidTotal && hasBalancedPayers;
  bool get isSaving => saveStatus == ExpenseSaveStatus.saving;

  AddExpenseState copyWith({ExpenseSaveStatus? saveStatus}) {
    return AddExpenseState(
      participants: participants,
      description: description,
      totalAmountCents: totalAmountCents,
      payerDrafts: payerDrafts,
      payersTotalCents: payersTotalCents,
      differenceCents: differenceCents,
      saveStatus: saveStatus ?? this.saveStatus,
    );
  }

  bool isPayerSelected(String participantId) {
    return payerDrafts.any((payer) => payer.participantId == participantId);
  }
}
