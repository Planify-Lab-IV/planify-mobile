import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/expenses/domain/expense.dart';
import 'package:planify/features/expenses/domain/new_expense.dart';
import 'package:planify/features/expenses/domain/expense_payer_draft.dart';
import 'package:planify/features/expenses/domain/expense_debtor_draft.dart';

void main() {
  test(
    'creation snapshot cannot change when caller edits the source lists',
    () {
      final payers = [
        const ExpensePayerDraft(participantId: 'p1', amountCents: 10000),
      ];
      final debtors = [
        const ExpenseDebtorDraft(participantId: 'p2', amountCents: 10000),
      ];
      final draft = NewExpense(
        description: 'Cena',
        totalAmountCents: 10000,
        payers: payers,
        debtors: debtors,
      );
      payers.clear();
      debtors.clear();
      expect(draft.payers.single.amountCents, 10000);
      expect(draft.debtors.single.amountCents, 10000);
      expect(() => draft.payers.clear(), throwsUnsupportedError);
      expect(() => draft.debtors.clear(), throwsUnsupportedError);
    },
  );

  test('persisted expense keeps immutable shares and backend metadata', () {
    final payers = [
      const ExpensePayerDraft(participantId: 'p1', amountCents: 10000),
    ];
    final expense = Expense(
      id: 'e1',
      eventId: 'event1',
      description: 'Cena',
      totalAmountCents: 10000,
      createdByParticipantId: 'p2',
      createdAt: DateTime.utc(2026, 10, 2),
      payers: payers,
      debtors: const [
        ExpenseDebtorDraft(participantId: 'p2', amountCents: 10000),
      ],
    );
    payers.clear();
    expect(expense.payers.single.participantId, 'p1');
    expect(expense.createdByParticipantId, 'p2');
    expect(() => expense.debtors.clear(), throwsUnsupportedError);
  });
}
