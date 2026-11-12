import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/data/dio_client.dart';
import 'package:planify/features/debts/data/http_debts_repository.dart';
import 'package:planify/features/debts/domain/debt_settlement.dart';
import 'package:planify/features/debts/domain/debt_status.dart';

void main() {
  const pendingDebt = {
    'id': 'debt-pending',
    'eventId': 'event-1',
    'debtor': {'participantId': 'participant-ana', 'username': 'Ana'},
    'creditor': {'participantId': 'participant-beto', 'username': 'Beto'},
    'amountCents': 1500,
    'status': 'pending',
    'settledAt': null,
  };
  const settledDebt = {
    'id': 'debt-settled',
    'eventId': 'event-1',
    'debtor': {'participantId': 'participant-beto', 'username': 'Beto'},
    'creditor': {'participantId': 'participant-ana', 'username': 'Ana'},
    'amountCents': 500,
    'status': 'settled',
    'settledAt': '2026-09-21T00:00:00.000Z',
  };
  const responseBody = {
    'debts': [pendingDebt, settledDebt],
    'allSettled': false,
  };

  Dio resolving(dynamic response, {void Function(RequestOptions)? inspect}) {
    final dio = DioClient.create(bearerToken: 'test-token');
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          inspect?.call(options);
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: response),
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

  Future<void> expectMappedError(DebtException exception, Dio dio) async {
    final repository = HttpDebtsRepository(dio: dio);
    await expectLater(
      repository.listEventDebts('event-1'),
      throwsA(
        isA<DebtException>().having(
          (error) => error.runtimeType,
          'type',
          exception.runtimeType,
        ),
      ),
    );
    await expectLater(
      repository.settleDebt('event-1', 'debt-1'),
      throwsA(
        isA<DebtException>().having(
          (error) => error.runtimeType,
          'type',
          exception.runtimeType,
        ),
      ),
    );
    await expectLater(
      repository.settleWithPerson('user:user-beto'),
      throwsA(
        isA<DebtException>().having(
          (error) => error.runtimeType,
          'type',
          exception.runtimeType,
        ),
      ),
    );
  }

  test('maps the event debt response and sends the session token', () async {
    RequestOptions? request;
    final repository = HttpDebtsRepository(
      dio: resolving(responseBody, inspect: (value) => request = value),
    );

    final debts = await repository.listEventDebts(' event-1 ');

    expect(request!.method, 'GET');
    expect(request!.path, '/events/event-1/debts');
    expect(request!.headers['Authorization'], 'Bearer test-token');
    expect(debts.allSettled, isFalse);
    expect(debts.debts, hasLength(2));
    expect(debts.debts.first.debtorParticipantId, 'participant-ana');
    expect(debts.debts.first.creditorName, 'Beto');
    expect(debts.debts.first.status, DebtStatus.pending);
    expect(debts.debts.first.settledAt, isNull);
    expect(debts.debts.last.status, DebtStatus.settled);
    expect(debts.debts.last.settledAt, DateTime.utc(2026, 9, 21));
  });

  test('posts the punctual and cascade settlement endpoints', () async {
    final requests = <RequestOptions>[];
    final repository = HttpDebtsRepository(
      dio: resolving(null, inspect: requests.add),
    );

    await repository.settleDebt(' event-1 ', ' debt-1 ');
    await repository.settleWithPerson(' user:user-beto ');

    expect(requests, hasLength(2));
    expect(requests[0].method, 'POST');
    expect(requests[0].path, '/events/event-1/debts/debt-1/settle');
    expect(requests[1].method, 'POST');
    expect(requests[1].path, '/me/balance/people/user%3Auser-beto/settle');
    expect(requests.every((request) => request.data == null), isTrue);
  });

  test('rejects blank path parameters without sending a request', () async {
    final repository = HttpDebtsRepository(dio: Dio());

    await expectLater(
      repository.listEventDebts(' '),
      throwsA(isA<DebtValidationException>()),
    );
    await expectLater(
      repository.settleDebt('event-1', ' '),
      throwsA(isA<DebtValidationException>()),
    );
    await expectLater(
      repository.settleWithPerson(' '),
      throwsA(isA<DebtValidationException>()),
    );
  });

  test('rejects malformed debt list responses', () async {
    for (final invalid in [
      null,
      [],
      {},
      {'debts': [], 'allSettled': 'false'},
      {
        'debts': [
          {...pendingDebt, 'amountCents': 0},
        ],
        'allSettled': false,
      },
      {
        'debts': [
          {...settledDebt, 'settledAt': 'not-a-date'},
        ],
        'allSettled': true,
      },
      {
        'debts': [
          {...pendingDebt, 'settledAt': '2026-09-21T00:00:00.000Z'},
        ],
        'allSettled': false,
      },
    ]) {
      await expectLater(
        HttpDebtsRepository(dio: resolving(invalid)).listEventDebts('event-1'),
        throwsA(isA<InvalidDebtResponseException>()),
      );
    }
  });

  for (final (status, code, exception) in <(int, String?, DebtException)>[
    (400, 'INVALID_DATA', const DebtValidationException()),
    (401, 'UNAUTHORIZED', const DebtAuthenticationException()),
    (403, 'FORBIDDEN', const DebtAuthorizationException()),
    (404, 'NOT_FOUND', const DebtNotFoundException()),
    (409, 'DEBT_ALREADY_SETTLED', const DebtAlreadySettledException()),
    (409, 'EVENT_UNAVAILABLE', const DebtOperationException()),
    (500, 'INTERNAL_SERVER_ERROR', const DebtOperationException()),
  ]) {
    test('maps $status / $code for every debt operation', () async {
      await expectMappedError(exception, rejecting(status, code: code));
    });
  }

  for (final type in [
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.sendTimeout,
  ]) {
    test('maps $type to a network error for every debt operation', () async {
      await expectMappedError(
        const DebtNetworkException(),
        rejecting(null, type: type),
      );
    });
  }
}
