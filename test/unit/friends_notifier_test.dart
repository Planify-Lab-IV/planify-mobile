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
