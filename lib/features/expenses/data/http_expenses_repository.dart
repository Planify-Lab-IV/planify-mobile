import 'package:dio/dio.dart';

import '../domain/expense.dart';
import '../domain/expense_debtor_draft.dart';
import '../domain/expense_payer_draft.dart';
import '../domain/expenses_repository.dart';
import '../domain/new_expense.dart';
import 'expenses_exceptions.dart';

class HttpExpensesRepository implements ExpensesRepository {
  final Dio dio;

  HttpExpensesRepository({required this.dio});

  @override
  Future<Expense> createExpense(String eventId, NewExpense expense) async {
    final path = _eventPath(eventId);
    try {
      final response = await dio.post<dynamic>(
        '$path/expenses',
        data: {
          'description': expense.description,
          'totalAmountCents': expense.totalAmountCents,
          'payers': [
            for (final payer in expense.payers)
              {
                'participantId': payer.participantId,
                'amountCents': payer.amountCents,
              },
          ],
          'debtors': [
            for (final debtor in expense.debtors)
              {
                'participantId': debtor.participantId,
                'amountCents': debtor.amountCents,
              },
          ],
        },
      );
      return _expenseFromResponse(response.data);
    } on DioException catch (error) {
      throw _mapError(error);
    } on ExpensesException {
      rethrow;
    } catch (_) {
      throw const InvalidExpenseResponseException();
    }
  }

  @override
  Future<void> closeExpenses(String eventId) async {
    final path = _eventPath(eventId);
    try {
      // The endpoint is idempotent and returns the updated event (200).
      await dio.post<dynamic>('$path/expenses/close');
    } on DioException catch (error) {
      throw _mapError(error);
    } on ExpensesException {
      rethrow;
    } catch (_) {
      throw const ExpenseOperationException();
    }
  }

  String _eventPath(String eventId) {
    final normalized = eventId.trim();
    if (normalized.isEmpty) throw const ExpenseValidationException();
    return '/events/${Uri.encodeComponent(normalized)}';
  }

  Expense _expenseFromResponse(dynamic data) {
    if (data is! Map) throw const InvalidExpenseResponseException();
    final createdAt = DateTime.tryParse(_string(data, 'createdAt'));
    final payers = data['payers'];
    final debtors = data['debtors'];
    if (createdAt == null ||
        payers is! List ||
        debtors is! List ||
        payers.isEmpty ||
        debtors.isEmpty) {
      throw const InvalidExpenseResponseException();
    }
    return Expense(
      id: _string(data, 'id'),
      eventId: _string(data, 'eventId'),
      description: _string(data, 'description'),
      totalAmountCents: _amount(data, 'totalAmountCents'),
      createdByParticipantId: _string(data, 'createdByParticipantId'),
      createdAt: createdAt,
      payers: [
        for (final payer in payers)
          ExpensePayerDraft(
            participantId: _string(payer, 'participantId'),
            amountCents: _amount(payer, 'amountCents'),
          ),
      ],
      debtors: [
        for (final debtor in debtors)
          ExpenseDebtorDraft(
            participantId: _string(debtor, 'participantId'),
            amountCents: _amount(debtor, 'amountCents'),
          ),
      ],
    );
  }

  String _string(dynamic data, String key) {
    final value = data is Map ? data[key] : null;
    if (value is! String || value.trim().isEmpty) {
      throw const InvalidExpenseResponseException();
    }
    return value;
  }

  int _amount(dynamic data, String key) {
    final value = data is Map ? data[key] : null;
    if (value is! int || value <= 0) {
      throw const InvalidExpenseResponseException();
    }
    return value;
  }

  ExpensesException _mapError(DioException error) {
    switch (error.response?.statusCode) {
      case 400:
        return const ExpenseValidationException();
      case 401:
        return const ExpenseAuthenticationException();
      case 403:
        return const ExpenseForbiddenException();
      case 404:
        return const ExpenseEventNotFoundException();
      case 409:
        final body = error.response?.data;
        return switch (body is Map ? body['error'] : null) {
          'EVENT_UNAVAILABLE' => const ExpenseEventUnavailableException(),
          'EXPENSES_CLOSED' => const ExpensesClosedException(),
          _ => const ExpenseOperationException(),
        };
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => const NetworkExpenseException(),
      _ => const ExpenseOperationException(),
    };
  }
}
