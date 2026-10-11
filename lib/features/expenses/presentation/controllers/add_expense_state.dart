import '../../../events/domain/event_participant.dart';
import '../../domain/expense_debtor_draft.dart';
import '../../domain/expense_payer_draft.dart';
import '../../domain/expense.dart';
import '../../data/expenses_exceptions.dart';

enum ExpenseSaveStatus { idle, submitting, success, failure }

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
  final ExpenseSaveStatus saveStatus;
  final ExpensesException? submissionError;
  final Expense? createdExpense;

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
    this.saveStatus = ExpenseSaveStatus.idle,
    this.submissionError,
    this.createdExpense,
  }) : participants = List<EventParticipant>.unmodifiable(participants),
       payerDrafts = List<ExpensePayerDraft>.unmodifiable(payerDrafts),
       debtorDrafts = List<ExpenseDebtorDraft>.unmodifiable(debtorDrafts);

  bool get hasDescription => description.trim().isNotEmpty;
  bool get hasValidTotal => totalAmountCents > 0;
  bool get hasPayers => payerDrafts.isNotEmpty;
  bool get hasPositivePayerAmounts =>
      payerDrafts.every((payer) => payer.amountCents > 0);
  bool get hasBalancedPayers =>
      hasPayers && hasPositivePayerAmounts && differenceCents == 0;
  bool get hasDebtors => debtorDrafts.isNotEmpty;
  bool get hasPositiveDebtorAmounts =>
      debtorDrafts.every((debtor) => debtor.amountCents > 0);
  bool get hasBalancedDebtors =>
      hasDebtors && hasPositiveDebtorAmounts && debtorDifferenceCents == 0;

  bool get isReadyForSubmission =>
      hasDescription &&
      hasValidTotal &&
      hasBalancedPayers &&
      hasBalancedDebtors;
  bool get isSaving => saveStatus == ExpenseSaveStatus.submitting;

  AddExpenseState copyWith({
    ExpenseSaveStatus? saveStatus,
    ExpensesException? submissionError,
    Expense? createdExpense,
    bool clearError = false,
  }) {
    return AddExpenseState(
      participants: participants,
      description: description,
      totalAmountCents: totalAmountCents,
      payerDrafts: payerDrafts,
      payersTotalCents: payersTotalCents,
      differenceCents: differenceCents,
      debtorDrafts: debtorDrafts,
      debtorsTotalCents: debtorsTotalCents,
      debtorDifferenceCents: debtorDifferenceCents,
      saveStatus: saveStatus ?? this.saveStatus,
      submissionError: clearError
          ? null
          : submissionError ?? this.submissionError,
      createdExpense: createdExpense ?? this.createdExpense,
    );
  }

  bool isPayerSelected(String participantId) {
    return payerDrafts.any((payer) => payer.participantId == participantId);
  }

  bool isDebtorSelected(String participantId) {
    return debtorDrafts.any((debtor) => debtor.participantId == participantId);
  }
}
