import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/domain/event_participant.dart';
import 'package:planify/features/expenses/data/fake_expenses_repository.dart';
import 'package:planify/features/expenses/data/expenses_exceptions.dart';
import 'package:planify/features/expenses/domain/expense.dart';
import 'package:planify/features/expenses/domain/new_expense.dart';
import 'package:planify/features/expenses/presentation/controllers/add_expense_notifier.dart';
import 'package:planify/features/expenses/presentation/controllers/add_expense_state.dart';
import 'package:planify/features/expenses/presentation/controllers/add_expense_context.dart';
import 'package:planify/features/expenses/presentation/controllers/expenses_providers.dart';

class ControlledExpensesRepository extends FakeExpensesRepository {
  final pending = Completer<Expense>();
  int calls = 0;
  NewExpense? submitted;
  String? eventId;
  @override
  Future<Expense> createExpense(String eventId, NewExpense expense) {
    calls++;
    this.eventId = eventId;
    submitted = expense;
    return pending.future;
  }
}

void main() {
  final participants = [
    for (var i = 1; i <= 4; i++)
      EventParticipant(
        id: 'p$i',
        eventId: 'event-1',
        userId: i == 4 ? null : 'u$i',
        username: 'Person $i',
        isAnonymous: i == 4,
        isOrganizer: i == 1,
      ),
  ];
  AddExpenseNotifier build(FakeExpensesRepository repository) =>
      AddExpenseNotifier(
        participants: participants,
        eventId: 'event-1',
        repository: repository,
      );
  void fill(AddExpenseNotifier notifier) {
    notifier.setDescription(' Cena ');
    notifier.setTotalAmountCents(10000);
    notifier.togglePayer('p1');
    notifier.togglePayer('p4');
    notifier.setPayerAmount('p1', 4000);
    notifier.setPayerAmount('p4', 6000);
    for (final id in ['p2', 'p3', 'p4']) {
      notifier.toggleDebtor(id);
    }
    notifier.splitDebtorsEvenly();
  }

  test(
    'submits multiple roles exactly, including anonymous participants and remainder',
    () async {
      final repository = FakeExpensesRepository(
        delay: Duration.zero,
        createdByParticipantId: 'p4',
      );
      final notifier = build(repository);
      addTearDown(notifier.dispose);
      fill(notifier);
      expect(await notifier.submit(), isTrue);
      final created = repository.expenses.single;
      expect(created.eventId, 'event-1');
      expect(created.description, 'Cena');
      expect(created.totalAmountCents, 10000);
      expect(created.createdByParticipantId, 'p4');
      expect(created.payers.map((p) => p.amountCents), [4000, 6000]);
      expect(created.debtors.map((d) => d.amountCents), [3333, 3333, 3334]);
      expect(notifier.state.createdExpense, same(created));
      expect(notifier.state.saveStatus, ExpenseSaveStatus.success);
      expect(await notifier.submit(), isFalse);
      expect(repository.expenses, hasLength(1));
    },
  );

  test('invalid form makes no repository call', () async {
    final repository = ControlledExpensesRepository();
    final notifier = build(repository);
    addTearDown(notifier.dispose);
    expect(await notifier.submit(), isFalse);
    expect(repository.calls, 0);
  });

  test(
    'double submission makes one call and freezes the submitted draft',
    () async {
      final repository = ControlledExpensesRepository();
      final notifier = build(repository);
      addTearDown(notifier.dispose);
      fill(notifier);
      final first = notifier.submit();
      expect(notifier.state.saveStatus, ExpenseSaveStatus.submitting);
      expect(await notifier.submit(), isFalse);
      notifier.setDescription('Edited');
      expect(notifier.state.description, 'Cena');
      expect(repository.calls, 1);
      expect(repository.eventId, 'event-1');
      final expense = await FakeExpensesRepository(
        delay: Duration.zero,
      ).createExpense('event-1', repository.submitted!);
      repository.pending.complete(expense);
      expect(await first, isTrue);
    },
  );

  test('failure preserves values and retry succeeds', () async {
    final repository = FakeExpensesRepository(
      delay: Duration.zero,
      shouldFailCreatingExpense: true,
    );
    final notifier = build(repository);
    addTearDown(notifier.dispose);
    fill(notifier);
    final payers = notifier.state.payerDrafts;
    final debtors = notifier.state.debtorDrafts;
    expect(await notifier.submit(), isFalse);
    expect(notifier.state.saveStatus, ExpenseSaveStatus.failure);
    expect(notifier.state.submissionError, isA<ExpenseOperationException>());
    expect(notifier.state.payerDrafts, payers);
    expect(notifier.state.debtorDrafts, debtors);
    repository.shouldFailCreatingExpense = false;
    expect(await notifier.submit(), isTrue);
    expect(notifier.state.submissionError, isNull);
  });

  test('completion after disposal does not update a dead notifier', () async {
    final repository = ControlledExpensesRepository();
    final notifier = build(repository);
    fill(notifier);
    final result = notifier.submit();
    notifier.dispose();
    repository.pending.completeError(const ExpenseOperationException());
    expect(await result, isFalse);
  });

  test('family keys survive rebuilds and isolate different events', () {
    final container = ProviderContainer(
      overrides: [
        expensesRepositoryProvider.overrideWithValue(
          FakeExpensesRepository(delay: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);
    final first = AddExpenseContext(
      eventId: 'event-1',
      participants: participants,
    );
    final rebuilt = AddExpenseContext(
      eventId: 'event-1',
      participants: List.of(participants),
    );
    final second = AddExpenseContext(
      eventId: 'event-2',
      participants: participants,
    );
    final subscription = container.listen(
      addExpenseNotifierProvider(first),
      (_, _) {},
    );
    addTearDown(subscription.close);
    container
        .read(addExpenseNotifierProvider(first).notifier)
        .setDescription('Cena');
    expect(
      container.read(addExpenseNotifierProvider(rebuilt)).description,
      'Cena',
    );
    expect(
      container.read(addExpenseNotifierProvider(second)).description,
      isEmpty,
    );
  });
}
