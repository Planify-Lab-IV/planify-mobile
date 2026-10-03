import '../domain/expenses_repository.dart';
import '../domain/expense.dart';
import '../domain/new_expense.dart';
import 'expenses_exceptions.dart';

// Persistencia en memoria para tests; producción usa HttpExpensesRepository.
class FakeExpensesRepository implements ExpensesRepository {
  final Duration delay;
  bool shouldFailClosingExpenses;
  bool shouldFailCreatingExpense;
  final String createdByParticipantId;
  final List<Expense> _expenses = [];
  List<Expense> get expenses => List.unmodifiable(_expenses);
  final Set<String> _closedEventIds = {};

  FakeExpensesRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldFailClosingExpenses = false,
    this.shouldFailCreatingExpense = false,
    this.createdByParticipantId = 'fake-creator',
  });

  @override
  Future<Expense> createExpense(String eventId, NewExpense expense) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldFailCreatingExpense) throw const ExpenseOperationException();
    if (areExpensesClosedFor(eventId)) throw const ExpensesClosedException();
    final created = Expense(
      id: 'fake-expense-${_expenses.length + 1}',
      eventId: eventId,
      description: expense.description,
      totalAmountCents: expense.totalAmountCents,
      createdByParticipantId: createdByParticipantId,
      createdAt: DateTime.now().toUtc(),
      payers: expense.payers,
      debtors: expense.debtors,
    );
    _expenses.add(created);
    return created;
  }

  bool areExpensesClosedFor(String eventId) =>
      _closedEventIds.contains(eventId);

  @override
  Future<void> closeExpenses(String eventId) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldFailClosingExpenses) {
      throw Exception('No se pudieron cerrar los gastos');
    }

    _closedEventIds.add(eventId);
  }
}
