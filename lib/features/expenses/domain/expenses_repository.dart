// Contrato de persistencia para gastos.
abstract interface class ExpensesRepository {
  Future<void> closeExpenses(String eventId);
}
