import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/data/event_exceptions.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/domain/event.dart';
import 'package:planify/features/events/domain/event_draft.dart';
import 'package:planify/features/events/domain/event_status.dart';

void main() {
  group('FakeEventsRepository', () {
    late FakeEventsRepository repository;
    const testOrganizerId = 'org-123';

    setUp(() {
      repository = FakeEventsRepository(delay: Duration.zero);
    });

    test(
      'createEvent con grupo existente crea el evento con datos del grupo y autor',
      () async {
        const draft = EventDraft(
          name: 'Cumpleaños de Lucas',
          location: 'Av. Corrientes 1234',
          isNewGroup: false,
          selectedGroupId: 'grp-1',
          selectedGroupName: 'Amigos del Fútbol',
        );

        final event = await repository.createEvent(draft, testOrganizerId);

        expect(event.id, startsWith('evt-'));
        expect(event.name, equals('Cumpleaños de Lucas'));
        expect(event.location, equals('Av. Corrientes 1234'));
        expect(event.organizerId, equals(testOrganizerId));
        expect(event.groupId, equals('grp-1'));
        expect(event.status, equals(EventStatus.active));

        final fetched = await repository.getEvent(event.id);
        expect(fetched, equals(event));
      },
    );

    test(
      'createEvent con grupo nuevo crea el evento asignando el grupo',
      () async {
        const draft = EventDraft(
          name: 'Asado de Fin de Año',
          location: 'Club Social',
          isNewGroup: true,
          newGroupName: 'Amigos de la Primaria',
          newGroupMembers: ['juan@gmail.com', '@pedro123'],
        );

        final event = await repository.createEvent(draft, testOrganizerId);

        expect(event.id, startsWith('evt-'));
        expect(event.name, equals('Asado de Fin de Año'));
        expect(event.location, equals('Club Social'));
        expect(event.groupId, startsWith('grp-'));
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

        expect(
          () => errorRepo.createEvent(draft, testOrganizerId),
          throwsException,
        );
      },
    );

    test('cancel muta el estado del evento a cancelled', () async {
      const draft = EventDraft(
        name: 'Evento a Cancelar',
        location: 'Lugar',
        selectedGroupId: 'grp-1',
      );
      final event = await repository.createEvent(draft, testOrganizerId);

      await repository.cancel(event.id);

      final updated = await repository.getEvent(event.id);
      expect(updated?.status, EventStatus.cancelled);
      expect(updated?.isCancelled, isTrue);
    });

    test(
      'cancel arroja EventNotFoundException si el evento no existe',
      () async {
        expect(
          () => repository.cancel('non-existent-id'),
          throwsA(isA<EventNotFoundException>()),
        );
      },
    );

    test(
      'cancel arroja EventCancellationException si shouldFailCancellation es true',
      () async {
        final failRepo = FakeEventsRepository(
          delay: Duration.zero,
          shouldFailCancellation: true,
        );
        final event = await failRepo.createEvent(
          const EventDraft(
            name: 'Evt',
            location: 'Loc',
            selectedGroupId: 'grp-1',
          ),
          testOrganizerId,
        );

        expect(
          () => failRepo.cancel(event.id),
          throwsA(isA<EventCancellationException>()),
        );
      },
    );

    test('permite inicializar con initialEvents personalizados', () async {
      final customEvent = Event(
        id: 'custom-1',
        name: 'Custom',
        location: 'Loc',
        organizerId: testOrganizerId,
        groupId: 'grp-1',
        status: EventStatus.active,
        createdAt: DateTime.now(),
      );

      final customRepo = FakeEventsRepository(
        delay: Duration.zero,
        initialEvents: [customEvent],
      );

      final fetched = await customRepo.getEvent('custom-1');
      expect(fetched, equals(customEvent));
    });
  });
}
