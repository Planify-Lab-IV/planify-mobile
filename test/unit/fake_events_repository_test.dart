import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/data/event_exceptions.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/domain/attendance_status.dart';
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

    test('guarda y recupera asistencia por evento y participante', () async {
      await repository.confirmAssistance(
        'evt-123',
        'participant-1',
        AttendanceStatus.confirmed.name,
      );
      await repository.confirmAssistance(
        'evt-123',
        'participant-2',
        AttendanceStatus.rejected.name,
      );

      expect(
        await repository.getAttendance('evt-123', 'participant-1'),
        AttendanceStatus.confirmed,
      );
      expect(
        await repository.getAttendance('evt-123', 'participant-2'),
        AttendanceStatus.rejected,
      );
    });

    test('rechaza estados de asistencia no soportados', () async {
      expect(
        () => repository.confirmAssistance('evt-123', 'participant-1', 'yes'),
        throwsA(isA<AttendanceResponseException>()),
      );
    });

    test(
      'simula un error al responder asistencia sin guardar cambios',
      () async {
        final failingRepository = FakeEventsRepository(
          delay: Duration.zero,
          shouldFailAttendanceResponse: true,
        );

        expect(
          () => failingRepository.confirmAssistance(
            'evt-123',
            'participant-1',
            AttendanceStatus.confirmed.name,
          ),
          throwsA(isA<AttendanceResponseException>()),
        );
        expect(
          await failingRepository.getAttendance('evt-123', 'participant-1'),
          isNull,
        );
      },
    );

    test(
      'carga eventos semilla por defecto cuando no se pasan initialEvents',
      () async {
        final defaultRepo = FakeEventsRepository(delay: Duration.zero);

        final evt123 = await defaultRepo.getEvent('evt-123');
        expect(evt123, isNotNull);
        expect(evt123?.name, equals('Cumpleaños de Lucas'));
        expect(evt123?.status, equals(EventStatus.active));

        final evtCumple = await defaultRepo.getEvent('evt-cumple-lucas');
        expect(evtCumple, isNotNull);

        final evtAsado = await defaultRepo.getEvent('evt-asado-amigos');
        expect(evtAsado, isNotNull);
      },
    );
  });
}
