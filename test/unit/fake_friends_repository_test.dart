import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/friends/data/fake_friends_repository.dart';
import 'package:planify/features/friends/data/friends_exceptions.dart';
import 'package:planify/features/friends/domain/friend_request.dart';
import 'package:planify/features/friends/domain/person.dart';

void main() {
  const ana = Person(
    id: 'ana',
    name: 'Ana Pérez',
    username: 'ana',
    relationship: FriendRelationship.none,
  );
  const bruno = Person(
    id: 'bruno',
    name: 'Bruno Díaz',
    username: 'bruno',
    relationship: FriendRelationship.none,
  );
  const carla = Person(
    id: 'carla',
    name: 'Carla Gómez',
    username: 'carla',
    relationship: FriendRelationship.none,
  );
  const diego = Person(
    id: 'diego',
    name: 'Diego Ruiz',
    username: 'diego',
    relationship: FriendRelationship.none,
  );

  FakeFriendsRepository repository({bool shouldThrowError = false}) {
    return FakeFriendsRepository(
      delay: Duration.zero,
      shouldThrowError: shouldThrowError,
      searchablePeople: const [ana, bruno, carla, diego],
      initialReceivedRequests: [
        FriendRequest(
          id: 'request-ana',
          user: ana,
          createdAt: DateTime(2026, 10, 20),
        ),
      ],
      initialSentRequests: [
        FriendRequest(
          id: 'request-bruno',
          user: bruno,
          createdAt: DateTime(2026, 10, 19),
        ),
      ],
      initialFriends: const [carla],
    );
  }

  group('FakeFriendsRepository', () {
    test(
      'expone la relación y requestId de cada resultado de búsqueda',
      () async {
        final fake = repository();

        final results = await Future.wait([
          fake.search('ana'),
          fake.search('bruno'),
          fake.search('carla'),
          fake.search('diego'),
        ]);

        expect(
          results[0].single.relationship,
          FriendRelationship.requestReceived,
        );
        expect(results[0].single.requestId, 'request-ana');
        expect(results[1].single.relationship, FriendRelationship.requestSent);
        expect(results[1].single.requestId, 'request-bruno');
        expect(results[2].single.relationship, FriendRelationship.friend);
        expect(results[2].single.requestId, isNull);
        expect(results[3].single.relationship, FriendRelationship.none);
      },
    );

    test('enviar una solicitud actualiza búsqueda y enviadas', () async {
      final fake = repository();

      final request = await fake.sendRequest(diego.id);

      expect(request.user.relationship, FriendRelationship.requestSent);
      expect((await fake.search('diego')).single.requestId, request.id);
      expect((await fake.getRequests()).sent.map((item) => item.id), [
        'request-bruno',
        request.id,
      ]);
    });

    test('aceptar una solicitud mueve a la persona a amigos', () async {
      final fake = repository();

      await fake.acceptRequest('request-ana');

      expect((await fake.getRequests()).received, isEmpty);
      expect((await fake.getFriends()).map((person) => person.id), [
        'carla',
        'ana',
      ]);
      expect(
        (await fake.search('ana')).single.relationship,
        FriendRelationship.friend,
      );
    });

    test(
      'rechazar o cancelar devuelve a la persona a ninguna relación',
      () async {
        final fake = repository();

        await fake.removeRequest('request-ana');
        await fake.removeRequest('request-bruno');

        final requests = await fake.getRequests();
        expect(requests.received, isEmpty);
        expect(requests.sent, isEmpty);
        expect(
          (await fake.search('ana')).single.relationship,
          FriendRelationship.none,
        );
        expect(
          (await fake.search('bruno')).single.relationship,
          FriendRelationship.none,
        );
      },
    );

    test(
      'una solicitud no disponible se elimina y expone un error específico',
      () async {
        final fake = repository();
        fake.markRequestUnavailable('request-ana');

        await expectLater(
          fake.acceptRequest('request-ana'),
          throwsA(isA<FriendRequestNotFoundException>()),
        );

        expect((await fake.getRequests()).received, isEmpty);
        expect(
          (await fake.search('ana')).single.relationship,
          FriendRelationship.none,
        );
      },
    );

    test('shouldThrowError simula una falla genérica', () async {
      final fake = repository(shouldThrowError: true);

      await expectLater(
        fake.getFriends(),
        throwsA(isA<FriendsOperationException>()),
      );
    });
  });
}
