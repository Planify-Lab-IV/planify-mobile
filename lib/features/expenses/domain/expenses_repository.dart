import 'expense.dart';
import 'new_expense.dart';

// Contrato de persistencia para gastos.
abstract interface class ExpensesRepository {
  Future<Expense> createExpense(String eventId, NewExpense expense);
  Future<void> closeExpenses(String eventId);
}
