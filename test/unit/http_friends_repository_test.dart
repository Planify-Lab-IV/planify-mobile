import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/friends/data/friends_exceptions.dart';
import 'package:planify/features/friends/data/http_friends_repository.dart';
import 'package:planify/features/friends/domain/person.dart';

void main() {
  const person = {'id': 'user-2', 'name': 'Dev Two', 'username': 'dev2'};

  Dio resolving(
    dynamic body, {
    void Function(RequestOptions options)? inspect,
    int statusCode = 200,
  }) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          inspect?.call(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: statusCode,
              data: body,
            ),
          );
        },
      ),
    );
    return dio;
  }

  Dio rejecting({
    required DioExceptionType type,
    int? statusCode,
    dynamic body,
  }) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: type,
            response: statusCode == null
                ? null
                : Response<dynamic>(
                    requestOptions: options,
                    statusCode: statusCode,
                    data: body,
                  ),
          ),
        ),
      ),
    );
    return dio;
  }

  Map<String, dynamic> request({
    required String id,
    required Map<String, dynamic> user,
  }) {
    return {'id': id, 'user': user, 'createdAt': '2026-10-27T12:00:00.000Z'};
  }

  group('HttpFriendsRepository', () {
    test(
      'searches with an encoded query parameter and maps relationships',
      () async {
        RequestOptions? requestOptions;
        final repository = HttpFriendsRepository(
          dio: resolving({
            'users': [
              {...person, 'relationship': 'none'},
              {
                ...person,
                'id': 'user-3',
                'relationship': 'request_sent',
                'requestId': 'request-sent',
              },
              {
                ...person,
                'id': 'user-4',
                'relationship': 'request_received',
                'requestId': 'request-received',
              },
              {...person, 'id': 'user-5', 'relationship': 'future_state'},
            ],
          }, inspect: (options) => requestOptions = options),
        );

        final people = await repository.search('ev 2#_%');

        expect(requestOptions?.method, 'GET');
        expect(requestOptions?.path, '/friends/search');
        expect(requestOptions?.queryParameters, {'q': 'ev 2#_%'});
        expect(requestOptions?.uri.queryParameters['q'], 'ev 2#_%');
        expect(people.map((person) => person.relationship), [
          FriendRelationship.none,
          FriendRelationship.requestSent,
          FriendRelationship.requestReceived,
          FriendRelationship.none,
        ]);
        expect(people[1].requestId, 'request-sent');
        expect(people[2].requestId, 'request-received');
      },
    );

    test('sends a request and maps the returned request', () async {
      RequestOptions? requestOptions;
      final repository = HttpFriendsRepository(
        dio: resolving({
          'request': request(id: 'request-1', user: person),
        }, inspect: (options) => requestOptions = options),
      );

      final result = await repository.sendRequest('user-2');

      expect(requestOptions?.method, 'POST');
      expect(requestOptions?.path, '/friends/requests');
      expect(requestOptions?.data, {'userId': 'user-2'});
      expect(result.id, 'request-1');
      expect(result.user.relationship, FriendRelationship.requestSent);
      expect(result.user.requestId, 'request-1');
    });

    test('gets received and sent requests with their directions', () async {
      RequestOptions? requestOptions;
      final repository = HttpFriendsRepository(
        dio: resolving({
          'received': [request(id: 'request-received', user: person)],
          'sent': [
            request(id: 'request-sent', user: {...person, 'id': 'user-3'}),
          ],
        }, inspect: (options) => requestOptions = options),
      );

      final requests = await repository.getRequests();

      expect(requestOptions?.method, 'GET');
      expect(requestOptions?.path, '/friends/requests');
      expect(
        requests.received.single.user.relationship,
        FriendRelationship.requestReceived,
      );
      expect(requests.received.single.user.requestId, 'request-received');
      expect(
        requests.sent.single.user.relationship,
        FriendRelationship.requestSent,
      );
      expect(requests.sent.single.user.requestId, 'request-sent');
    });

    test('accepts and removes requests using their endpoint paths', () async {
      RequestOptions? acceptedRequest;
      RequestOptions? removedRequest;
      final acceptingRepository = HttpFriendsRepository(
        dio: resolving(null, inspect: (options) => acceptedRequest = options),
      );
      final removingRepository = HttpFriendsRepository(
        dio: resolving(null, inspect: (options) => removedRequest = options),
      );

      await acceptingRepository.acceptRequest('request-1');
      await removingRepository.removeRequest('request-2');

      expect(acceptedRequest?.method, 'POST');
      expect(acceptedRequest?.path, '/friends/requests/request-1/accept');
      expect(removedRequest?.method, 'DELETE');
      expect(removedRequest?.path, '/friends/requests/request-2');
    });

    test('gets friends and assigns the friend relationship', () async {
      RequestOptions? requestOptions;
      final repository = HttpFriendsRepository(
        dio: resolving({
          'friends': [person],
        }, inspect: (options) => requestOptions = options),
      );

      final friends = await repository.getFriends();

      expect(requestOptions?.method, 'GET');
      expect(requestOptions?.path, '/friends');
      expect(friends.single.relationship, FriendRelationship.friend);
      expect(friends.single.requestId, isNull);
    });

    test(
      'rejects malformed responses, invalid relationships, and pending relationships without an id',
      () async {
        final malformedRepository = HttpFriendsRepository(
          dio: resolving({'users': 'not-a-list'}),
        );
        final missingRequestIdRepository = HttpFriendsRepository(
          dio: resolving({
            'users': [
              {...person, 'relationship': 'request_received'},
            ],
          }),
        );
        final missingRelationshipRepository = HttpFriendsRepository(
          dio: resolving({
            'users': [person],
          }),
        );
        final nonStringRelationshipRepository = HttpFriendsRepository(
          dio: resolving({
            'users': [
              {...person, 'relationship': 1},
            ],
          }),
        );

        await expectLater(
          malformedRepository.search('de'),
          throwsA(isA<InvalidFriendsResponseException>()),
        );
        await expectLater(
          missingRequestIdRepository.search('de'),
          throwsA(isA<InvalidFriendsResponseException>()),
        );
        await expectLater(
          missingRelationshipRepository.search('de'),
          throwsA(isA<InvalidFriendsResponseException>()),
        );
        await expectLater(
          nonStringRelationshipRepository.search('de'),
          throwsA(isA<InvalidFriendsResponseException>()),
        );
      },
    );

    test('maps the recoverable 409 and only the documented 404', () async {
      final conflictRepository = HttpFriendsRepository(
        dio: rejecting(
          type: DioExceptionType.badResponse,
          statusCode: 409,
          body: {'error': 'FRIENDSHIP_ALREADY_EXISTS'},
        ),
      );
      final unavailableRepository = HttpFriendsRepository(
        dio: rejecting(
          type: DioExceptionType.badResponse,
          statusCode: 404,
          body: {'error': 'FRIEND_REQUEST_NOT_FOUND'},
        ),
      );
      final otherNotFoundRepository = HttpFriendsRepository(
        dio: rejecting(
          type: DioExceptionType.badResponse,
          statusCode: 404,
          body: {'error': 'ROUTE_NOT_FOUND'},
        ),
      );

      await expectLater(
        conflictRepository.sendRequest('user-2'),
        throwsA(isA<FriendshipAlreadyExistsException>()),
      );
      await expectLater(
        unavailableRepository.acceptRequest('request-1'),
        throwsA(isA<FriendRequestNotFoundException>()),
      );
      await expectLater(
        otherNotFoundRepository.acceptRequest('request-1'),
        throwsA(isA<InvalidFriendsResponseException>()),
      );
    });

    test('maps connection failures to a network exception', () async {
      final repository = HttpFriendsRepository(
        dio: rejecting(type: DioExceptionType.connectionError),
      );

      await expectLater(
        repository.search('de'),
        throwsA(isA<NetworkFriendsException>()),
      );
    });
  });
}
