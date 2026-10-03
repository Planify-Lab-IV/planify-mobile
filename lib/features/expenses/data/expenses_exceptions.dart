sealed class ExpensesException implements Exception {
  const ExpensesException();
}

class ExpenseValidationException extends ExpensesException {
  const ExpenseValidationException();
}

class ExpenseAuthenticationException extends ExpensesException {
  const ExpenseAuthenticationException();
}

class ExpenseForbiddenException extends ExpensesException {
  const ExpenseForbiddenException();
}

class ExpenseEventNotFoundException extends ExpensesException {
  const ExpenseEventNotFoundException();
}

class ExpenseEventUnavailableException extends ExpensesException {
  const ExpenseEventUnavailableException();
}

class ExpensesClosedException extends ExpensesException {
  const ExpensesClosedException();
}

class NetworkExpenseException extends ExpensesException {
  const NetworkExpenseException();
}

class InvalidExpenseResponseException extends ExpensesException {
  const InvalidExpenseResponseException();
}

class ExpenseOperationException extends ExpensesException {
  const ExpenseOperationException();
}
