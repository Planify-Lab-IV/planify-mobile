import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/data/event_exceptions.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/domain/event.dart';
import 'package:planify/features/events/domain/event_status.dart';

void main() {
  group('FakeEventsRepository Unit Tests', () {
    late FakeEventsRepository repository;

    setUp(() {
      repository = FakeEventsRepository(delay: Duration.zero);
    });

    test('getEvent retorna el evento por defecto', () async {
      final event = await repository.getEvent(
        FakeEventsRepository.defaultEventId,
      );

      expect(event, isNotNull);
      expect(event!.id, FakeEventsRepository.defaultEventId);
      expect(event.name, 'Cumpleaños de Lucas');
      expect(event.location, 'Av. Corrientes 1234');
      expect(event.organizerId, FakeEventsRepository.defaultOrganizerId);
      expect(event.status, EventStatus.active);
      expect(event.isActive, isTrue);
    });

    test('getEvent retorna null para ID inexistente', () async {
      final event = await repository.getEvent('id-inexistente');
      expect(event, isNull);
    });

    test('cancelar muta el estado del evento a cancelled en memoria', () async {
      final initialEvent = await repository.getEvent(
        FakeEventsRepository.defaultEventId,
      );
      expect(initialEvent?.status, EventStatus.active);

      await repository.cancel(FakeEventsRepository.defaultEventId);

      final updatedEvent = await repository.getEvent(
        FakeEventsRepository.defaultEventId,
      );
      expect(updatedEvent?.status, EventStatus.cancelled);
      expect(updatedEvent?.isCancelled, isTrue);
      expect(updatedEvent?.isActive, isFalse);
    });

    test('cancelar arroja EventNotFoundException si el evento no existe', () {
      expect(
        () => repository.cancel('evento-desconocido'),
        throwsA(isA<EventNotFoundException>()),
      );
    });

    test(
      'cancelar arroja EventCancellationException si el evento es errorEventId',
      () {
        expect(
          () => repository.cancel(FakeEventsRepository.errorEventId),
          throwsA(isA<EventCancellationException>()),
        );
      },
    );

    test(
      'cancelar arroja EventCancellationException cuando shouldFailCancellation es true',
      () {
        repository.shouldFailCancellation = true;

        expect(
          () => repository.cancel(FakeEventsRepository.defaultEventId),
          throwsA(isA<EventCancellationException>()),
        );
      },
    );

    test('permite inicializar con lista personalizada de eventos', () async {
      const customEvent = Event(
        id: 'custom-123',
        name: 'Hackathon',
        location: 'Campus UTN',
        organizerId: 'org-custom',
        status: EventStatus.active,
      );

      final customRepo = FakeEventsRepository(
        delay: Duration.zero,
        initialEvents: [customEvent],
      );

      final fetched = await customRepo.getEvent('custom-123');
      expect(fetched, equals(customEvent));

      await customRepo.cancel('custom-123');
      final afterCancel = await customRepo.getEvent('custom-123');
      expect(afterCancel?.isCancelled, isTrue);
    });
  });
}
