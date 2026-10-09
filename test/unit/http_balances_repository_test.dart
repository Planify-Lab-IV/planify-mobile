import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/balances/data/balances_exceptions.dart';
import 'package:planify/features/balances/data/http_balances_repository.dart';
import 'package:planify/features/balances/domain/balance_direction.dart';
import 'package:planify/features/balances/domain/person_balance_status.dart';

void main() {
  group('HttpBalancesRepository', () {
    Dio dioResolving(dynamic body, void Function(RequestOptions)? inspect) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            inspect?.call(options);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: body,
              ),
            );
          },
        ),
      );
      return dio;
    }

    Dio dioRejecting({int? statusCode, DioExceptionType? type}) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: type ?? DioExceptionType.unknown,
              response: statusCode == null
                  ? null
                  : Response<dynamic>(
                      requestOptions: options,
                      statusCode: statusCode,
                    ),
            ),
          ),
        ),
      );
      return dio;
    }

    Dio dioRespondingByPath(Map<String, dynamic> responses) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: responses[options.path],
              ),
            );
          },
        ),
      );
      return dio;
    }

    test('gets and maps the balance summary', () async {
      RequestOptions? request;
      final repository = HttpBalancesRepository(
        dio: dioResolving({
          'owedToMeCents': 70000,
          'iOweCents': 30000,
        }, (options) => request = options),
      );

      final summary = await repository.getSummary();

      expect(request?.method, 'GET');
      expect(request?.path, '/me/balance');
      expect(summary.owedToMeCents, 70000);
      expect(summary.iOweCents, 30000);
    });

    test('gets and maps balances for each person', () async {
      RequestOptions? request;
      final repository = HttpBalancesRepository(
        dio: dioResolving([
          {
            'personKey': 'user:dev2',
            'displayName': 'dev2',
            'status': 'pending',
            'netCents': 20000,
          },
          {
            'personKey': 'participant:guest',
            'displayName': 'Invitado',
            'status': 'pay',
            'netCents': 5000,
          },
        ], (options) => request = options),
      );

      final people = await repository.listPeople();

      expect(request?.method, 'GET');
      expect(request?.path, '/me/balance/people');
      expect(people, hasLength(2));
      expect(people.first.personKey, 'user:dev2');
      expect(people.first.status, PersonBalanceStatus.pending);
      expect(people.last.status, PersonBalanceStatus.pay);
    });

    test('encodes the person key and maps the event breakdown', () async {
      RequestOptions? request;
      final repository = HttpBalancesRepository(
        dio: dioResolving({
          'personKey': 'user:dev2',
          'displayName': 'dev2',
          'status': 'pending',
          'netCents': 20000,
          'breakdown': [
            {
              'eventId': 'event-1',
              'eventName': 'Evento 1',
              'amountCents': 50000,
              'direction': 'owed_to_me',
            },
            {
              'eventId': 'event-2',
              'eventName': 'Evento 2',
              'amountCents': 30000,
              'direction': 'i_owe',
            },
          ],
        }, (options) => request = options),
      );

      final detail = await repository.getPersonDetail('user:dev2');

      expect(request?.method, 'GET');
      expect(request?.path, '/me/balance/people/user%3Adev2');
      expect(detail.netCents, 20000);
      expect(detail.breakdown, hasLength(2));
      expect(detail.breakdown.first.direction, BalanceDirection.owedToMe);
      expect(detail.breakdown.last.direction, BalanceDirection.iOwe);
    });

    test(
      'preserves compensation per person and uncompensated event breakdowns',
      () async {
        final repository = HttpBalancesRepository(
          dio: dioRespondingByPath({
            '/me/balance': {'owedToMeCents': 70000, 'iOweCents': 30000},
            '/me/balance/people': [
              {
                'personKey': 'user:dev2',
                'displayName': 'dev2',
                'status': 'pending',
                'netCents': 20000,
              },
              {
                'personKey': 'user:dev3',
                'displayName': 'dev3',
                'status': 'pending',
                'netCents': 20000,
              },
              {
                'personKey': 'participant:guest-1',
                'displayName': 'Invitado',
                'status': 'pay',
                'netCents': 4000,
              },
            ],
            '/me/balance/people/user%3Adev2': {
              'personKey': 'user:dev2',
              'displayName': 'dev2',
              'status': 'pending',
              'netCents': 20000,
              'breakdown': [
                {
                  'eventId': 'event-1',
                  'eventName': 'Evento 1',
                  'amountCents': 50000,
                  'direction': 'owed_to_me',
                },
                {
                  'eventId': 'event-2',
                  'eventName': 'Evento 2',
                  'amountCents': 30000,
                  'direction': 'i_owe',
                },
              ],
            },
            '/me/balance/people/participant%3Aguest-1': {
              'personKey': 'participant:guest-1',
              'displayName': 'Invitado',
              'status': 'pay',
              'netCents': 4000,
              'breakdown': [
                {
                  'eventId': 'event-3',
                  'eventName': 'Evento 3',
                  'amountCents': 4000,
                  'direction': 'i_owe',
                },
              ],
            },
          }),
        );

        final summary = await repository.getSummary();
        final people = await repository.listPeople();
        final dev2Detail = await repository.getPersonDetail('user:dev2');
        final anonymousDetail = await repository.getPersonDetail(
          'participant:guest-1',
        );

        expect(summary.owedToMeCents, 70000);
        expect(summary.iOweCents, 30000);
        expect(people, hasLength(3));
        expect(
          people
              .singleWhere((person) => person.personKey == 'user:dev2')
              .netCents,
          20000,
        );
        expect(
          people
              .singleWhere((person) => person.personKey == 'user:dev3')
              .netCents,
          20000,
        );
        expect(
          people
              .singleWhere(
                (person) => person.personKey == 'participant:guest-1',
              )
              .netCents,
          4000,
        );
        expect(dev2Detail.breakdown.map((line) => line.amountCents), [
          50000,
          30000,
        ]);
        expect(dev2Detail.breakdown.map((line) => line.direction), [
          BalanceDirection.owedToMe,
          BalanceDirection.iOwe,
        ]);
        expect(anonymousDetail.breakdown.single.amountCents, 4000);
        expect(
          anonymousDetail.breakdown.single.direction,
          BalanceDirection.iOwe,
        );
      },
    );

    test('rejects malformed responses', () async {
      final repository = HttpBalancesRepository(
        dio: dioResolving({'owedToMeCents': 70000}, null),
      );

      expect(
        repository.getSummary,
        throwsA(isA<InvalidBalancesResponseException>()),
      );
    });

    test('rejects invalid person balance values', () async {
      final repository = HttpBalancesRepository(
        dio: dioResolving([
          {
            'personKey': 'user:dev2',
            'displayName': 'dev2',
            'status': 'unknown',
            'netCents': 20000,
          },
        ], null),
      );

      expect(
        repository.listPeople,
        throwsA(isA<InvalidBalancesResponseException>()),
      );
    });

    test('maps connection errors to a network exception', () async {
      final repository = HttpBalancesRepository(
        dio: dioRejecting(type: DioExceptionType.connectionError),
      );

      expect(repository.getSummary, throwsA(isA<NetworkBalancesException>()));
    });

    test(
      'maps an unauthorized response to an authentication exception',
      () async {
        final repository = HttpBalancesRepository(
          dio: dioRejecting(statusCode: 401),
        );

        expect(
          repository.listPeople,
          throwsA(isA<AuthenticationBalancesException>()),
        );
      },
    );

    test('rejects a blank person key before sending a request', () async {
      final repository = HttpBalancesRepository(dio: Dio());

      expect(
        () => repository.getPersonDetail('  '),
        throwsA(isA<InvalidBalancesResponseException>()),
      );
    });
  });
}
