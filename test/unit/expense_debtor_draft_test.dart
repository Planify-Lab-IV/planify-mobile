import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/expenses/domain/expense_debtor_draft.dart';

void main() {
  group('ExpenseDebtorDraft', () {
    const draft = ExpenseDebtorDraft(
      participantId: 'participant-1',
      amountCents: 1250,
    );

    test('stores the participant ID and amount in cents', () {
      expect(draft.participantId, 'participant-1');
      expect(draft.amountCents, 1250);
    });

    test('copyWith changes only the requested fields', () {
      final withNewAmount = draft.copyWith(amountCents: 3000);
      final withNewParticipant = draft.copyWith(participantId: 'participant-2');

      expect(withNewAmount.participantId, 'participant-1');
      expect(withNewAmount.amountCents, 3000);
      expect(withNewParticipant.participantId, 'participant-2');
      expect(withNewParticipant.amountCents, 1250);
    });

    test('uses structural equality and hashCode', () {
      const sameDraft = ExpenseDebtorDraft(
        participantId: 'participant-1',
        amountCents: 1250,
      );
      const differentDraft = ExpenseDebtorDraft(
        participantId: 'participant-1',
        amountCents: 1251,
      );

      expect(draft, sameDraft);
      expect(draft.hashCode, sameDraft.hashCode);
      expect(draft, isNot(differentDraft));
      expect(draft.toString(), contains('participant-1'));
    });
  });
}
