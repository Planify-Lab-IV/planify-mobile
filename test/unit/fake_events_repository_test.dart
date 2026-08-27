import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/domain/event_draft.dart';

void main() {
  group('FakeEventsRepository', () {
    late FakeEventsRepository repository;

    setUp(() {
      repository = FakeEventsRepository(delay: Duration.zero);
    });

    test(
      'createEvent con grupo existente crea el evento con datos del grupo',
      () async {
        const draft = EventDraft(
          name: 'Cumpleaños de Lucas',
          location: 'Av. Corrientes 1234',
          isNewGroup: false,
          selectedGroupId: 'grp-1',
          selectedGroupName: 'Amigos del Fútbol',
        );

        final event = await repository.createEvent(draft);

        expect(event.id, startsWith('evt-'));
        expect(event.name, equals('Cumpleaños de Lucas'));
        expect(event.location, equals('Av. Corrientes 1234'));
        expect(event.groupId, equals('grp-1'));
        expect(event.groupName, equals('Amigos del Fútbol'));
        expect(event.memberIdentifiers, isEmpty);
      },
    );

    test(
      'createEvent con grupo nuevo crea el evento con identificadores de miembros',
      () async {
        const draft = EventDraft(
          name: 'Asado de Fin de Año',
          location: 'Club Social',
          isNewGroup: true,
          newGroupName: 'Amigos de la Primaria',
          newGroupMembers: ['juan@gmail.com', '@pedro123'],
        );

        final event = await repository.createEvent(draft);

        expect(event.id, startsWith('evt-'));
        expect(event.name, equals('Asado de Fin de Año'));
        expect(event.location, equals('Club Social'));
        expect(event.groupId, startsWith('grp-'));
        expect(event.groupName, equals('Amigos de la Primaria'));
        expect(
          event.memberIdentifiers,
          containsAll(['juan@gmail.com', '@pedro123']),
        );
      },
    );

    test(
      'createEvent arroja excepción cuando shouldThrowError es true',
      () async {
        final errorRepo = FakeEventsRepository(
          delay: Duration.zero,
          shouldThrowError: true,
        );

        const draft = EventDraft(
          name: 'Evento',
          location: 'Lugar',
          selectedGroupId: 'grp-1',
        );

        expect(() => errorRepo.createEvent(draft), throwsException);
      },
    );
  });
}
