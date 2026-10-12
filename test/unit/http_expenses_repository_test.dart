import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/data/dio_client.dart';
import 'package:planify/features/expenses/data/expenses_exceptions.dart';
import 'package:planify/features/expenses/data/http_expenses_repository.dart';
import 'package:planify/features/expenses/domain/expense_payer_draft.dart';
import 'package:planify/features/expenses/domain/expense_debtor_draft.dart';
import 'package:planify/features/expenses/domain/new_expense.dart';

void main() {
  final draft = NewExpense(
    description: 'Cena',
    totalAmountCents: 10000,
    payers: const [
      ExpensePayerDraft(participantId: 'p1', amountCents: 4000),
      ExpensePayerDraft(participantId: 'p2', amountCents: 6000),
    ],
    debtors: const [
      ExpenseDebtorDraft(participantId: 'p1', amountCents: 3333),
      ExpenseDebtorDraft(participantId: 'p2', amountCents: 3333),
      ExpenseDebtorDraft(participantId: 'p3', amountCents: 3334),
    ],
  );
  const body = {
    'id': 'expense-1',
    'eventId': 'event-1',
    'description': 'Cena',
    'totalAmountCents': 10000,
    'createdByParticipantId': 'p3',
    'createdAt': '2026-10-02T12:00:00.000Z',
    'payers': [
      {'participantId': 'p1', 'amountCents': 4000},
      {'participantId': 'p2', 'amountCents': 6000},
    ],
    'debtors': [
      {'participantId': 'p1', 'amountCents': 3333},
      {'participantId': 'p2', 'amountCents': 3333},
      {'participantId': 'p3', 'amountCents': 3334},
    ],
  };

  Dio resolving(
    dynamic response, {
    void Function(RequestOptions)? inspect,
    int statusCode = 201,
  }) {
    final dio = DioClient.create(bearerToken: 'test-token');
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          inspect?.call(options);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: statusCode,
              data: response,
            ),
          );
        },
      ),
    );
    return dio;
  }

  Dio rejecting(
    int? status, {
    String? code,
    DioExceptionType type = DioExceptionType.badResponse,
  }) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: type,
              response: status == null
                  ? null
                  : Response(
                      requestOptions: options,
                      statusCode: status,
                      data: {'error': code},
                    ),
            ),
          );
        },
      ),
    );
    return dio;
  }

  test(
    'posts exact cents and participant IDs with session token; maps all fields',
    () async {
      RequestOptions? request;
      final repository = HttpExpensesRepository(
        dio: resolving(body, inspect: (value) => request = value),
      );
      final expense = await repository.createExpense(' event-1 ', draft);
      expect(request!.method, 'POST');
      expect(request!.path, '/events/event-1/expenses');
      expect(request!.headers['Authorization'], 'Bearer test-token');
      expect(request!.data, {
        'description': 'Cena',
        'totalAmountCents': 10000,
        'payers': body['payers'],
        'debtors': body['debtors'],
      });
      expect(expense.id, 'expense-1');
      expect(expense.eventId, 'event-1');
      expect(expense.description, 'Cena');
      expect(expense.totalAmountCents, 10000);
      expect(expense.createdByParticipantId, 'p3');
      expect(expense.createdAt, DateTime.utc(2026, 10, 2, 12));
      expect(expense.payers, draft.payers);
      expect(expense.debtors, draft.debtors);
    },
  );

  test('rejects blank event IDs without sending a request', () async {
    final repository = HttpExpensesRepository(dio: Dio());
    await expectLater(
      repository.createExpense(' ', draft),
      throwsA(isA<ExpenseValidationException>()),
    );
    await expectLater(
      repository.closeExpenses(' '),
      throwsA(isA<ExpenseValidationException>()),
    );
  });

  test('rejects malformed success responses', () async {
    for (final invalid in [
      null,
      [],
      {},
      {...body, 'createdAt': 'invalid'},
      {...body, 'totalAmountCents': 10000.5},
      {...body, 'payers': []},
      {
        ...body,
        'debtors': [
          {'amountCents': 10000},
        ],
      },
    ]) {
      await expectLater(
        HttpExpensesRepository(
          dio: resolving(invalid),
        ).createExpense('event-1', draft),
        throwsA(isA<InvalidExpenseResponseException>()),
      );
    }
  });

  final cases = <(int, String?, Matcher)>[
    (400, 'INVALID_DATA', isA<ExpenseValidationException>()),
    (401, null, isA<ExpenseAuthenticationException>()),
    (403, 'FORBIDDEN', isA<ExpenseForbiddenException>()),
    (404, 'NOT_FOUND', isA<ExpenseEventNotFoundException>()),
    (409, 'EVENT_UNAVAILABLE', isA<ExpenseEventUnavailableException>()),
    (409, 'EXPENSES_CLOSED', isA<ExpensesClosedException>()),
    (409, 'UNKNOWN', isA<ExpenseOperationException>()),
    (500, null, isA<ExpenseOperationException>()),
  ];
  for (final (status, code, matcher) in cases) {
    test('maps $status / $code for creation and closure', () async {
      final repository = HttpExpensesRepository(
        dio: rejecting(status, code: code),
      );
      await expectLater(
        repository.createExpense('event-1', draft),
        throwsA(matcher),
      );
      await expectLater(repository.closeExpenses('event-1'), throwsA(matcher));
    });
  }
  for (final type in [
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.sendTimeout,
  ]) {
    test('maps $type to connection error', () async {
      final repository = HttpExpensesRepository(
        dio: rejecting(null, type: type),
      );
      await expectLater(
        repository.createExpense('event-1', draft),
        throwsA(isA<NetworkExpenseException>()),
      );
      await expectLater(
        repository.closeExpenses('event-1'),
        throwsA(isA<NetworkExpenseException>()),
      );
    });
  }

  test('closes using POST and accepts repeated successful closure', () async {
    final requests = <RequestOptions>[];
    final repository = HttpExpensesRepository(
      dio: resolving(
        {'expensesClosed': true},
        inspect: requests.add,
        statusCode: 200,
      ),
    );
    await repository.closeExpenses('event-1');
    await repository.closeExpenses('event-1');
    expect(requests, hasLength(2));
    for (final request in requests) {
      expect(request.method, 'POST');
      expect(request.path, '/events/event-1/expenses/close');
      expect(request.data, isNull);
    }
  });
}
