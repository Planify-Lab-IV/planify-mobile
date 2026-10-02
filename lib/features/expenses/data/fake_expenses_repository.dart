import '../domain/expenses_repository.dart';

// Implementación temporal usada mientras no existe el endpoint de gastos.
class FakeExpensesRepository implements ExpensesRepository {
  final Duration delay;
  bool shouldFailClosingExpenses;
  final Set<String> _closedEventIds = {};

  FakeExpensesRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldFailClosingExpenses = false,
  });

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
