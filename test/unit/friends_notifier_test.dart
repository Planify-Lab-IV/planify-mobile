import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/friends/data/fake_friends_repository.dart';
import 'package:planify/features/friends/data/friends_exceptions.dart';
import 'package:planify/features/friends/domain/friend_request.dart';
import 'package:planify/features/friends/domain/friend_requests.dart';
import 'package:planify/features/friends/domain/friends_repository.dart';
import 'package:planify/features/friends/domain/person.dart';
import 'package:planify/features/friends/presentation/controllers/friends_notifier.dart';
import 'package:planify/features/friends/presentation/controllers/friends_state.dart';

void main() {
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  FriendsNotifier notifier(FriendsRepository repository) {
    return FriendsNotifier(
      repository: repository,
      searchDebounce: Duration.zero,
    );
  }

  group('FriendsNotifier', () {
    test('carga solicitudes y amigos de forma independiente', () async {
      final friendsNotifier = notifier(
        FakeFriendsRepository(delay: Duration.zero),
      );
      await settle();

      expect(friendsNotifier.state.requestsStatus, FriendsLoadStatus.success);
      expect(friendsNotifier.state.friendsStatus, FriendsLoadStatus.success);
      expect(friendsNotifier.state.requests.received, hasLength(1));
      expect(friendsNotifier.state.friends, hasLength(1));
      friendsNotifier.dispose();
    });

    test('no busca hasta que la consulta tiene dos caracteres', () async {
      final repository = _ControlledSearchRepository();
      final friendsNotifier = notifier(repository);
      await settle();

      friendsNotifier.updateSearchQuery('a');
      await settle();

      expect(repository.searchCalls, isZero);
      expect(friendsNotifier.state.searchStatus, FriendsLoadStatus.idle);
      friendsNotifier.dispose();
    });

    test('descarta el resultado de una búsqueda anterior', () async {
      final repository = _ControlledSearchRepository();
      final friendsNotifier = notifier(repository);
      await settle();

      friendsNotifier.updateSearchQuery('an');
      await settle();
      friendsNotifier.updateSearchQuery('ana');
      await settle();

      expect(repository.searchCalls, 2);
      repository.responses[1].complete([_ana]);
      await settle();
      repository.responses[0].complete([_bruno]);
      await settle();

      expect(friendsNotifier.state.searchResults, [_ana]);
      expect(friendsNotifier.state.searchStatus, FriendsLoadStatus.success);
      friendsNotifier.dispose();
    });

    for (final scenario in _pendingSearchScenarios) {
      test(
        'reenvía la búsqueda pendiente cuando ${scenario.description}',
        () async {
          final repository = _PendingSearchActionRepository(scenario.action);
          final friendsNotifier = FriendsNotifier(
            repository: repository,
            searchDebounce: const Duration(days: 1),
          );
          await settle();

          final action = switch (scenario.action) {
            _FriendAction.send => friendsNotifier.sendRequest(scenario.person),
            _FriendAction.accept => friendsNotifier.acceptRequest(
              scenario.person,
            ),
            _FriendAction.remove => friendsNotifier.removeRequest(
              scenario.person,
            ),
          };
          friendsNotifier.updateSearchQuery('die');
          repository.completeAction();

          expect(await action, FriendActionResult.success);
          await settle();

          expect(repository.searchCalls, 1);
          repository.responses.single.complete([scenario.expectedPerson]);
          await settle();

          expect(friendsNotifier.state.searchStatus, FriendsLoadStatus.success);
          expect(friendsNotifier.state.searchResults, [
            scenario.expectedPerson,
          ]);
          friendsNotifier.dispose();
        },
      );
    }

    test(
      'no repite una búsqueda que ya terminó al enviar una solicitud',
      () async {
        final repository = _PendingSearchActionRepository(_FriendAction.send);
        final friendsNotifier = notifier(repository);
        await settle();

        friendsNotifier.updateSearchQuery('di');
        await settle();
        repository.responses.single.complete([_diego]);
        await settle();

        final action = friendsNotifier.sendRequest(_diego);
        repository.completeAction();

        expect(await action, FriendActionResult.success);
        expect(repository.searchCalls, 1);
        expect(friendsNotifier.state.searchStatus, FriendsLoadStatus.success);
        friendsNotifier.dispose();
      },
    );

    test('enviar una solicitud actualiza resultados y enviadas', () async {
      final repository = FakeFriendsRepository(delay: Duration.zero);
      final friendsNotifier = notifier(repository);
      await settle();
      friendsNotifier.updateSearchQuery('diego');
      await settle();

      final result = await friendsNotifier.sendRequest(
        friendsNotifier.state.searchResults.single,
      );

      expect(result, FriendActionResult.success);
      expect(
        friendsNotifier.state.searchResults.single.relationship,
        FriendRelationship.requestSent,
      );
      expect(friendsNotifier.state.requests.sent, hasLength(2));
      friendsNotifier.dispose();
    });

    test('aceptar actualiza solicitudes, amigos y búsqueda', () async {
      final repository = FakeFriendsRepository(delay: Duration.zero);
      final friendsNotifier = notifier(repository);
      await settle();
      friendsNotifier.updateSearchQuery('ana');
      await settle();

      final result = await friendsNotifier.acceptRequest(
        friendsNotifier.state.searchResults.single,
      );

      expect(result, FriendActionResult.success);
      expect(friendsNotifier.state.requests.received, isEmpty);
      expect(
        friendsNotifier.state.friends.any((person) => person.username == 'ana'),
        isTrue,
      );
      expect(
        friendsNotifier.state.searchResults.single.relationship,
        FriendRelationship.friend,
      );
      friendsNotifier.dispose();
    });

    test(
      'rechazar y cancelar quitan la solicitud y restauran la búsqueda',
      () async {
        final repository = FakeFriendsRepository(delay: Duration.zero);
        final friendsNotifier = notifier(repository);
        await settle();
        friendsNotifier.updateSearchQuery('ana');
        await settle();

        final rejected = await friendsNotifier.removeRequest(
          friendsNotifier.state.searchResults.single,
        );
        friendsNotifier.updateSearchQuery('bruno');
        await settle();
        final cancelled = await friendsNotifier.removeRequest(
          friendsNotifier.state.searchResults.single,
        );

        expect(rejected, FriendActionResult.success);
        expect(cancelled, FriendActionResult.success);
        expect(friendsNotifier.state.requests.received, isEmpty);
        expect(friendsNotifier.state.requests.sent, isEmpty);
        expect(
          friendsNotifier.state.searchResults.single.relationship,
          FriendRelationship.none,
        );
        friendsNotifier.dispose();
      },
    );

    test('devuelve falla y conserva el estado si una acción falla', () async {
      final repository = FakeFriendsRepository(delay: Duration.zero);
      final friendsNotifier = notifier(repository);
      await settle();
      friendsNotifier.updateSearchQuery('diego');
      await settle();
      final person = friendsNotifier.state.searchResults.single;
      repository.shouldThrowError = true;

      final result = await friendsNotifier.sendRequest(person);

      expect(result, FriendActionResult.failure);
      expect(friendsNotifier.state.searchResults.single, person);
      expect(friendsNotifier.state.pendingPersonIds, isEmpty);
      friendsNotifier.dispose();
    });

    test('recarga el estado remoto si la relación ya existe', () async {
      final repository = _FriendshipConflictRepository();
      final friendsNotifier = notifier(repository);
      await settle();
      friendsNotifier.updateSearchQuery('diego');
      await settle();
      final person = friendsNotifier.state.searchResults.single;

      final result = await friendsNotifier.sendRequest(person);

      expect(result, FriendActionResult.success);
      expect(
        friendsNotifier.state.searchResults.single.relationship,
        FriendRelationship.requestSent,
      );
      expect(friendsNotifier.state.requests.sent, hasLength(1));
      expect(friendsNotifier.state.pendingPersonIds, isEmpty);
      friendsNotifier.dispose();
    });

    test('conserva las solicitudes cuando aceptar o eliminar fallan', () async {
      final repository = FakeFriendsRepository(delay: Duration.zero);
      final friendsNotifier = notifier(repository);
      await settle();
      final received = friendsNotifier.state.requests.received.single.user;
      final sent = friendsNotifier.state.requests.sent.single.user;
      repository.shouldThrowError = true;

      final acceptResult = await friendsNotifier.acceptRequest(received);
      final removeResult = await friendsNotifier.removeRequest(sent);

      expect(acceptResult, FriendActionResult.failure);
      expect(removeResult, FriendActionResult.failure);
      expect(friendsNotifier.state.requests.received, hasLength(1));
      expect(friendsNotifier.state.requests.sent, hasLength(1));
      expect(friendsNotifier.state.pendingPersonIds, isEmpty);
      friendsNotifier.dispose();
    });

    test('recarga cuando una solicitud ya no está disponible', () async {
      final repository = FakeFriendsRepository(delay: Duration.zero);
      final friendsNotifier = notifier(repository);
      await settle();
      friendsNotifier.updateSearchQuery('ana');
      await settle();
      final person = friendsNotifier.state.searchResults.single;
      repository.markRequestUnavailable(person.requestId!);

      final result = await friendsNotifier.acceptRequest(person);

      expect(result, FriendActionResult.requestUnavailable);
      expect(friendsNotifier.state.requests.received, isEmpty);
      expect(
        friendsNotifier.state.searchResults.single.relationship,
        FriendRelationship.none,
      );
      expect(friendsNotifier.state.pendingPersonIds, isEmpty);
      friendsNotifier.dispose();
    });

    test(
      'recarga cuando eliminar una solicitud encuentra que ya no está disponible',
      () async {
        final repository = FakeFriendsRepository(delay: Duration.zero);
        final friendsNotifier = notifier(repository);
        await settle();
        friendsNotifier.updateSearchQuery('bruno');
        await settle();
        final person = friendsNotifier.state.searchResults.single;
        repository.markRequestUnavailable(person.requestId!);

        final result = await friendsNotifier.removeRequest(person);

        expect(result, FriendActionResult.requestUnavailable);
        expect(friendsNotifier.state.requests.sent, isEmpty);
        expect(
          friendsNotifier.state.searchResults.single.relationship,
          FriendRelationship.none,
        );
        expect(friendsNotifier.state.pendingPersonIds, isEmpty);
        friendsNotifier.dispose();
      },
    );
  });
}

const _ana = Person(
  id: 'ana',
  name: 'Ana Pérez',
  username: 'ana',
  relationship: FriendRelationship.none,
);

const _bruno = Person(
  id: 'bruno',
  name: 'Bruno Díaz',
  username: 'bruno',
  relationship: FriendRelationship.none,
);

const _diego = Person(
  id: 'diego',
  name: 'Diego Ruiz',
  username: 'diego',
  relationship: FriendRelationship.none,
);

const _anaRequestReceived = Person(
  id: 'ana',
  name: 'Ana Pérez',
  username: 'ana',
  relationship: FriendRelationship.requestReceived,
  requestId: 'request-ana',
);

const _brunoRequestSent = Person(
  id: 'bruno',
  name: 'Bruno Díaz',
  username: 'bruno',
  relationship: FriendRelationship.requestSent,
  requestId: 'request-bruno',
);

const _pendingSearchScenarios = [
  _PendingSearchScenario(
    description: 'envía una solicitud',
    action: _FriendAction.send,
    person: _diego,
    expectedPerson: Person(
      id: 'diego',
      name: 'Diego Ruiz',
      username: 'diego',
      relationship: FriendRelationship.requestSent,
      requestId: 'request-diego',
    ),
  ),
  _PendingSearchScenario(
    description: 'acepta una solicitud',
    action: _FriendAction.accept,
    person: _anaRequestReceived,
    expectedPerson: Person(
      id: 'ana',
      name: 'Ana Pérez',
      username: 'ana',
      relationship: FriendRelationship.friend,
    ),
  ),
  _PendingSearchScenario(
    description: 'elimina una solicitud',
    action: _FriendAction.remove,
    person: _brunoRequestSent,
    expectedPerson: _bruno,
  ),
];

enum _FriendAction { send, accept, remove }

class _PendingSearchScenario {
  final String description;
  final _FriendAction action;
  final Person person;
  final Person expectedPerson;

  const _PendingSearchScenario({
    required this.description,
    required this.action,
    required this.person,
    required this.expectedPerson,
  });
}

class _ControlledSearchRepository implements FriendsRepository {
  final responses = <Completer<List<Person>>>[];
  var searchCalls = 0;

  @override
  Future<List<Person>> search(String query) {
    searchCalls++;
    final response = Completer<List<Person>>();
    responses.add(response);
    return response.future;
  }

  @override
  Future<FriendRequest> sendRequest(String userId) {
    throw const FriendsOperationException();
  }

  @override
  Future<FriendRequests> getRequests() async => FriendRequests();

  @override
  Future<void> acceptRequest(String requestId) {
    throw const FriendsOperationException();
  }

  @override
  Future<void> removeRequest(String requestId) {
    throw const FriendsOperationException();
  }

  @override
  Future<List<Person>> getFriends() async => const [];
}

class _PendingSearchActionRepository implements FriendsRepository {
  final _FriendAction action;
  final responses = <Completer<List<Person>>>[];
  final _actionCompletion = Completer<void>();
  var searchCalls = 0;

  _PendingSearchActionRepository(this.action);

  void completeAction() => _actionCompletion.complete();

  @override
  Future<List<Person>> search(String query) {
    searchCalls++;
    final response = Completer<List<Person>>();
    responses.add(response);
    return response.future;
  }

  @override
  Future<FriendRequest> sendRequest(String userId) async {
    if (action != _FriendAction.send) {
      throw const FriendsOperationException();
    }
    await _actionCompletion.future;
    return FriendRequest(
      id: 'request-diego',
      user: const Person(
        id: 'diego',
        name: 'Diego Ruiz',
        username: 'diego',
        relationship: FriendRelationship.requestSent,
        requestId: 'request-diego',
      ),
      createdAt: DateTime(2026, 10, 23),
    );
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    if (action != _FriendAction.accept) {
      throw const FriendsOperationException();
    }
    await _actionCompletion.future;
  }

  @override
  Future<void> removeRequest(String requestId) async {
    if (action != _FriendAction.remove) {
      throw const FriendsOperationException();
    }
    await _actionCompletion.future;
  }

  @override
  Future<FriendRequests> getRequests() async => FriendRequests();

  @override
  Future<List<Person>> getFriends() async => const [];
}

class _FriendshipConflictRepository implements FriendsRepository {
  var _relationshipAlreadyExists = false;

  @override
  Future<List<Person>> search(String query) async {
    return [
      _diego.copyWith(
        relationship: _relationshipAlreadyExists
            ? FriendRelationship.requestSent
            : FriendRelationship.none,
        requestId: _relationshipAlreadyExists ? 'request-diego' : null,
        clearRequestId: !_relationshipAlreadyExists,
      ),
    ];
  }

  @override
  Future<FriendRequest> sendRequest(String userId) async {
    _relationshipAlreadyExists = true;
    throw const FriendshipAlreadyExistsException();
  }

  @override
  Future<FriendRequests> getRequests() async {
    if (!_relationshipAlreadyExists) return FriendRequests();
    return FriendRequests(
      sent: [
        FriendRequest(
          id: 'request-diego',
          user: _diego.copyWith(
            relationship: FriendRelationship.requestSent,
            requestId: 'request-diego',
          ),
          createdAt: DateTime(2026, 10, 27),
        ),
      ],
    );
  }

  @override
  Future<List<Person>> getFriends() async => const [];

  @override
  Future<void> acceptRequest(String requestId) {
    throw const FriendsOperationException();
  }

  @override
  Future<void> removeRequest(String requestId) {
    throw const FriendsOperationException();
  }
}
