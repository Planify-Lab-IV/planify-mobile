import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/domain/event_participant.dart';
import 'package:planify/features/expenses/presentation/controllers/add_expense_notifier.dart';

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
      userId: null,
      username: 'Juan',
      isAnonymous: true,
      isOrganizer: false,
    ),
    EventParticipant(
      id: 'participant-3',
      eventId: 'event-1',
      userId: 'user-3',
      username: 'Ana',
      isAnonymous: false,
      isOrganizer: false,
    ),
  ];

  AddExpenseNotifier buildNotifier() {
    return AddExpenseNotifier(participants: participants);
  }

  group('AddExpenseNotifier', () {
    test('keeps event participants and initializes an empty draft', () {
      final notifier = buildNotifier();

      expect(notifier.state.participants, participants);
      expect(notifier.state.description, isEmpty);
      expect(notifier.state.totalAmountCents, 0);
      expect(notifier.state.payerDrafts, isEmpty);
      expect(notifier.state.differenceCents, 0);
      expect(notifier.state.debtorDrafts, isEmpty);
      expect(notifier.state.debtorDifferenceCents, 0);
      expect(notifier.state.isReadyForSubmission, isFalse);
    });

    test('normalizes the description and tracks submission requirements', () {
      final notifier = buildNotifier();

      notifier.setDescription('  Cena  ');
      notifier.setTotalAmountCents(1200);
      notifier.togglePayer('participant-1');
      notifier.toggleDebtor('participant-1');

      expect(notifier.state.description, 'Cena');
      expect(notifier.state.hasDescription, isTrue);
      expect(notifier.state.isReadyForSubmission, isTrue);
    });

    test('a single payer is automatically assigned the full total', () {
      final notifier = buildNotifier();

      notifier.setTotalAmountCents(1250);
      notifier.togglePayer('participant-1');

      expect(notifier.state.payerDrafts.single.amountCents, 1250);
      expect(notifier.state.payersTotalCents, 1250);
      expect(notifier.state.differenceCents, 0);

      notifier.setPayerAmount('participant-1', 900);
      expect(notifier.state.payerDrafts.single.amountCents, 1250);

      notifier.setTotalAmountCents(2000);
      expect(notifier.state.payerDrafts.single.amountCents, 2000);
    });

    test(
      'multiple payers can have different amounts and expose the difference',
      () {
        final notifier = buildNotifier();

        notifier.setTotalAmountCents(1000);
        notifier.togglePayer('participant-1');
        notifier.togglePayer('participant-2');
        notifier.setPayerAmount('participant-1', 300);
        notifier.setPayerAmount('participant-2', 800);

        expect(notifier.state.payersTotalCents, 1100);
        expect(notifier.state.differenceCents, -100);
        expect(notifier.state.hasBalancedPayers, isFalse);
      },
    );

    test(
      'splits selected payers exactly and assigns the remainder to the last',
      () {
        final notifier = buildNotifier();

        notifier.setTotalAmountCents(1001);
        notifier.togglePayer('participant-1');
        notifier.togglePayer('participant-2');
        notifier.togglePayer('participant-3');
        notifier.splitPayersEvenly();

        expect(notifier.state.payerDrafts.map((payer) => payer.amountCents), [
          333,
          333,
          335,
        ]);
        expect(notifier.state.differenceCents, 0);
        expect(notifier.state.hasBalancedPayers, isTrue);
      },
    );

    test('removing down to one payer assigns the full total again', () {
      final notifier = buildNotifier();

      notifier.setTotalAmountCents(1000);
      notifier.togglePayer('participant-1');
      notifier.togglePayer('participant-2');
      notifier.setPayerAmount('participant-1', 400);
      notifier.setPayerAmount('participant-2', 600);
      notifier.togglePayer('participant-2');

      expect(notifier.state.payerDrafts, hasLength(1));
      expect(notifier.state.payerDrafts.single.amountCents, 1000);
      expect(notifier.state.differenceCents, 0);
    });

    test('a single debtor is automatically assigned the full total', () {
      final notifier = buildNotifier();

      notifier.setTotalAmountCents(1250);
      notifier.toggleDebtor('participant-1');

      expect(notifier.state.debtorDrafts.single.amountCents, 1250);
      expect(notifier.state.debtorsTotalCents, 1250);
      expect(notifier.state.debtorDifferenceCents, 0);

      notifier.setDebtorAmount('participant-1', 900);
      expect(notifier.state.debtorDrafts.single.amountCents, 1250);

      notifier.setTotalAmountCents(2000);
      expect(notifier.state.debtorDrafts.single.amountCents, 2000);
    });

    test(
      'multiple debtors can have different amounts and expose the difference',
      () {
        final notifier = buildNotifier();

        notifier.setTotalAmountCents(1000);
        notifier.toggleDebtor('participant-1');
        notifier.toggleDebtor('participant-2');
        notifier.setDebtorAmount('participant-1', 300);
        notifier.setDebtorAmount('participant-2', 800);

        expect(notifier.state.debtorsTotalCents, 1100);
        expect(notifier.state.debtorDifferenceCents, -100);
        expect(notifier.state.hasBalancedDebtors, isFalse);
      },
    );

    test(
      'splits selected debtors exactly and assigns the remainder to the last',
      () {
        final notifier = buildNotifier();

        notifier.setTotalAmountCents(1001);
        notifier.toggleDebtor('participant-1');
        notifier.toggleDebtor('participant-2');
        notifier.toggleDebtor('participant-3');
        notifier.splitDebtorsEvenly();

        expect(
          notifier.state.debtorDrafts.map((debtor) => debtor.amountCents),
          [333, 333, 335],
        );
        expect(notifier.state.debtorDifferenceCents, 0);
        expect(notifier.state.hasBalancedDebtors, isTrue);
      },
    );

    test('removing debtors down to one assigns the full total again', () {
      final notifier = buildNotifier();

      notifier.setTotalAmountCents(1000);
      notifier.toggleDebtor('participant-1');
      notifier.toggleDebtor('participant-2');
      notifier.setDebtorAmount('participant-1', 400);
      notifier.setDebtorAmount('participant-2', 600);
      notifier.toggleDebtor('participant-2');

      expect(notifier.state.debtorDrafts, hasLength(1));
      expect(notifier.state.debtorDrafts.single.amountCents, 1000);
      expect(notifier.state.debtorDifferenceCents, 0);
    });

    test(
      'keeps payer and debtor roles independent for the same participant',
      () {
        final notifier = buildNotifier();

        notifier.setTotalAmountCents(1000);
        notifier.togglePayer('participant-1');
        notifier.toggleDebtor('participant-1');
        notifier.toggleDebtor('participant-2');
        notifier.setDebtorAmount('participant-1', 400);
        notifier.setDebtorAmount('participant-2', 600);

        expect(notifier.state.isPayerSelected('participant-1'), isTrue);
        expect(notifier.state.isDebtorSelected('participant-1'), isTrue);
        expect(notifier.state.payerDrafts.single.amountCents, 1000);
        expect(notifier.state.debtorDifferenceCents, 0);
      },
    );

    test('does not save when the debtor side is incomplete', () async {
      final notifier = buildNotifier();

      notifier.setDescription('Cena');
      notifier.setTotalAmountCents(1000);
      notifier.togglePayer('participant-1');

      final wasSaved = await notifier.save();

      expect(notifier.state.hasBalancedPayers, isTrue);
      expect(notifier.state.hasDebtors, isFalse);
      expect(notifier.state.isReadyForSubmission, isFalse);
      expect(wasSaved, isFalse);
      expect(notifier.state.isSaving, isFalse);
    });

    test('saves the combined payer and debtor draft locally', () async {
      final notifier = buildNotifier();

      notifier.setDescription('Cena');
      notifier.setTotalAmountCents(1000);
      notifier.togglePayer('participant-1');
      notifier.toggleDebtor('participant-2');

      final saveFuture = notifier.save();

      expect(notifier.state.isSaving, isTrue);
      expect(await saveFuture, isTrue);
      expect(notifier.state.isSaving, isFalse);
    });

    test('rejects invalid totals, amounts and participants', () {
      final notifier = buildNotifier();

      expect(() => notifier.setTotalAmountCents(-1), throwsArgumentError);
      expect(() => notifier.togglePayer('unknown'), throwsArgumentError);
      expect(() => notifier.toggleDebtor('unknown'), throwsArgumentError);

      notifier.togglePayer('participant-1');
      notifier.togglePayer('participant-2');
      expect(
        () => notifier.setPayerAmount('participant-1', -1),
        throwsArgumentError,
      );
      expect(
        () => notifier.setPayerAmount('participant-3', 100),
        throwsArgumentError,
      );
      notifier.toggleDebtor('participant-1');
      notifier.toggleDebtor('participant-2');
      expect(
        () => notifier.setDebtorAmount('participant-1', -1),
        throwsArgumentError,
      );
      expect(
        () => notifier.setDebtorAmount('participant-3', 100),
        throwsArgumentError,
      );
    });
  });
}
