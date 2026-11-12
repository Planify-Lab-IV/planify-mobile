import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/friends/domain/friend_request.dart';
import 'package:planify/features/friends/domain/friend_requests.dart';
import 'package:planify/features/friends/domain/person.dart';

void main() {
  const person = Person(
    id: 'person-1',
    name: 'Ana Pérez',
    username: 'ana',
    relationship: FriendRelationship.requestSent,
    requestId: 'request-1',
  );

  group('Person', () {
    test('copyWith puede quitar el identificador de una solicitud', () {
      final updated = person.copyWith(
        relationship: FriendRelationship.none,
        clearRequestId: true,
      );

      expect(updated.relationship, FriendRelationship.none);
      expect(updated.requestId, isNull);
      expect(updated.id, person.id);
    });

    test('compara todos los datos que la pantalla usa para una relación', () {
      expect(person, equals(person.copyWith()));
      expect(
        person,
        isNot(equals(person.copyWith(relationship: FriendRelationship.friend))),
      );
    });
  });

  group('FriendRequests', () {
    final request = FriendRequest(
      id: 'request-1',
      user: person,
      createdAt: DateTime(2026, 10, 21),
    );

    test('defiende sus listas de cambios externos', () {
      final received = [request];
      final requests = FriendRequests(received: received);
      received.clear();

      expect(requests.received, [request]);
      expect(() => requests.received.clear(), throwsUnsupportedError);
    });

    test('copyWith conserva la dirección no reemplazada', () {
      final sent = request.copyWith(id: 'request-2');
      final requests = FriendRequests(received: [request]);

      final updated = requests.copyWith(sent: [sent]);

      expect(updated.received, [request]);
      expect(updated.sent, [sent]);
    });
  });
}
