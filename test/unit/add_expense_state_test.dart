import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/domain/event_participant.dart';
import 'package:planify/features/expenses/domain/expense_debtor_draft.dart';
import 'package:planify/features/expenses/domain/expense_payer_draft.dart';
import 'package:planify/features/expenses/presentation/controllers/add_expense_state.dart';

void main() {
  const participants = [
    EventParticipant(
      id: 'participant-1',
      eventId: 'event-1',
      userId: 'user-1',
      username: 'Lucía',
      isAnonymous: false,
      isOrganizer: true,
    ),
    EventParticipant(
      id: 'participant-2',
      eventId: 'event-1',
      userId: 'user-2',
      username: 'Ana',
      isAnonymous: false,
      isOrganizer: false,
    ),
  ];

  group('AddExpenseState debtor fields', () {
    test('starts without debtors and is not ready for submission', () {
      final state = AddExpenseState(participants: participants);

      expect(state.debtorDrafts, isEmpty);
      expect(state.debtorsTotalCents, 0);
      expect(state.debtorDifferenceCents, 0);
      expect(state.hasDebtors, isFalse);
      expect(state.hasBalancedDebtors, isFalse);
      expect(state.isReadyForSubmission, isFalse);
    });

    test('tracks debtors separately from payers in a complete draft', () {
      final state = AddExpenseState(
        participants: participants,
        description: 'Cena',
        totalAmountCents: 1000,
        payerDrafts: const [
          ExpensePayerDraft(participantId: 'participant-1', amountCents: 1000),
        ],
        payersTotalCents: 1000,
        differenceCents: 0,
        debtorDrafts: const [
          ExpenseDebtorDraft(participantId: 'participant-1', amountCents: 500),
          ExpenseDebtorDraft(participantId: 'participant-2', amountCents: 500),
        ],
        debtorsTotalCents: 1000,
        debtorDifferenceCents: 0,
      );

      expect(state.isPayerSelected('participant-1'), isTrue);
      expect(state.isDebtorSelected('participant-1'), isTrue);
      expect(state.isDebtorSelected('participant-2'), isTrue);
      expect(state.isPayerSelected('participant-2'), isFalse);
      expect(state.hasBalancedPayers, isTrue);
      expect(state.hasBalancedDebtors, isTrue);
      expect(state.isReadyForSubmission, isTrue);
    });

    test('does not consider unbalanced debtors ready for submission', () {
      final state = AddExpenseState(
        participants: participants,
        description: 'Cena',
        totalAmountCents: 1000,
        payerDrafts: const [
          ExpensePayerDraft(participantId: 'participant-1', amountCents: 1000),
        ],
        payersTotalCents: 1000,
        debtorDrafts: const [
          ExpenseDebtorDraft(participantId: 'participant-2', amountCents: 800),
        ],
        debtorsTotalCents: 800,
        debtorDifferenceCents: 200,
      );

      expect(state.hasBalancedDebtors, isFalse);
      expect(state.isReadyForSubmission, isFalse);
    });
  });
}
