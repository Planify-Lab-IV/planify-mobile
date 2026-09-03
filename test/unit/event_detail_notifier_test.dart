import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/domain/event.dart';
import 'package:planify/features/events/domain/event_status.dart';
import 'package:planify/features/events/detail/controllers/event_detail_notifier.dart';
import 'package:planify/features/events/detail/controllers/event_detail_state.dart';

void main() {
  group('EventDetailNotifier Unit Tests', () {
    const testOrganizerId = 'org-123';
    const otherUserId = 'usr-999';
    const testEventId = 'evt-test-123';
    final fixedCreatedAt = DateTime(2026, 11, 1);
    final testDate = DateTime(2026, 11, 15, 21, 0);

    final testEvent = Event(
      id: testEventId,
      name: 'Cumpleaños de Lucas',
      location: 'Av. Corrientes 1234',
      organizerId: testOrganizerId,
      groupId: 'grp-amigos',
      status: EventStatus.active,
      createdAt: fixedCreatedAt,
      date: testDate,
    );

    const organizerSession = OrganizerSession(
      userId: testOrganizerId,
      email: 'lucas@planify.com',
      name: 'Lucas',
      token: 'fake-token',
    );

    const otherOrganizerSession = OrganizerSession(
      userId: otherUserId,
      email: 'otro@planify.com',
      name: 'Otro Organizador',
      token: 'fake-token-2',
    );

    const guestSession = AnonymousSession(
      userId: 'anon-456',
      name: 'Invitado',
      eventId: testEventId,
      token: 'fake-anon-token',
    );

    group(
      'Lógica de autorización "soy organizador de este evento puntual"',
      () {
        test(
          'retorna true si session.userId coincide con event.organizerId',
          () {
            final result = EventDetailNotifier.isUserOrganizerOfEvent(
              session: organizerSession,
              event: testEvent,
            );
            expect(result, isTrue);
          },
        );

        test(
          'retorna false si session.userId no coincide con event.organizerId',
          () {
            final result = EventDetailNotifier.isUserOrganizerOfEvent(
              session: otherOrganizerSession,
              event: testEvent,
            );
            expect(result, isFalse);
          },
        );

        test('retorna false si la sesión es un invitado / anónimo', () {
          final result = EventDetailNotifier.isUserOrganizerOfEvent(
            session: guestSession,
            event: testEvent,
          );
          expect(result, isFalse);
        });

        test('retorna false si la sesión es nula (usuario no autenticado)', () {
          final result = EventDetailNotifier.isUserOrganizerOfEvent(
            session: null,
            event: testEvent,
          );
          expect(result, isFalse);
        });

        test('retorna false si el evento es nulo', () {
          final result = EventDetailNotifier.isUserOrganizerOfEvent(
            session: organizerSession,
            event: null,
          );
          expect(result, isFalse);
        });

        test('retorna false si los IDs están vacíos o con espacios', () {
          const emptyIdSession = OrganizerSession(
            userId: '  ',
            email: '',
            name: '',
            token: '',
          );
          final emptyOrganizerEvent = Event(
            id: 'evt-1',
            name: '',
            location: '',
            organizerId: '  ',
            groupId: 'grp-1',
            createdAt: fixedCreatedAt,
          );

          expect(
            EventDetailNotifier.isUserOrganizerOfEvent(
              session: emptyIdSession,
              event: testEvent,
            ),
            isFalse,
          );
          expect(
            EventDetailNotifier.isUserOrganizerOfEvent(
              session: organizerSession,
              event: emptyOrganizerEvent,
            ),
            isFalse,
          );
        });
      },
    );

    group('canCancelEvent', () {
      test('es true para el organizador del evento activo', () {
        final repo = FakeEventsRepository(delay: Duration.zero);
        final notifier = EventDetailNotifier(
          repository: repo,
          currentSession: organizerSession,
          eventId: testEventId,
          initialEvent: testEvent,
        );

        expect(notifier.isOrganizer, isTrue);
        expect(notifier.canCancelEvent, isTrue);
      });

      test('es false si el evento ya fue cancelado', () {
        final repo = FakeEventsRepository(delay: Duration.zero);
        final cancelledEvent = testEvent.copyWith(
          status: EventStatus.cancelled,
        );
        final notifier = EventDetailNotifier(
          repository: repo,
          currentSession: organizerSession,
          eventId: testEventId,
          initialEvent: cancelledEvent,
        );

        expect(notifier.isOrganizer, isTrue);
        expect(notifier.canCancelEvent, isFalse);
      });

      test('es false si el usuario no es organizador de este evento', () {
        final repo = FakeEventsRepository(delay: Duration.zero);
        final notifier = EventDetailNotifier(
          repository: repo,
          currentSession: guestSession,
          eventId: testEventId,
          initialEvent: testEvent,
        );

        expect(notifier.isOrganizer, isFalse);
        expect(notifier.canCancelEvent, isFalse);
      });
    });

    group('loadEvent', () {
      test('carga exitosamente el evento desde el repositorio', () async {
        final repo = FakeEventsRepository(
          delay: Duration.zero,
          initialEvents: [testEvent],
        );
        final notifier = EventDetailNotifier(
          repository: repo,
          currentSession: organizerSession,
          eventId: testEventId,
        );

        await Future<void>.delayed(Duration.zero);

        expect(notifier.state.loadStatus, EventDetailLoadStatus.success);
        expect(notifier.state.isSuccess, isTrue);
        expect(notifier.state.event, equals(testEvent));
        expect(notifier.state.hasLoadError, isFalse);
      });

      test('marca error si el evento no existe en el repositorio', () async {
        final repo = FakeEventsRepository(
          delay: Duration.zero,
          initialEvents: [],
        );
        final notifier = EventDetailNotifier(
          repository: repo,
          currentSession: organizerSession,
          eventId: 'id-inexistente',
        );

        await Future<void>.delayed(Duration.zero);

        expect(notifier.state.loadStatus, EventDetailLoadStatus.error);
        expect(notifier.state.hasLoadError, isTrue);
        expect(notifier.state.event, isNull);
      });
    });

    group('cancelEvent', () {
      test('cancela el evento exitosamente y actualiza el estado', () async {
        final repo = FakeEventsRepository(
          delay: Duration.zero,
          initialEvents: [testEvent],
        );
        final notifier = EventDetailNotifier(
          repository: repo,
          currentSession: organizerSession,
          eventId: testEventId,
          initialEvent: testEvent,
        );

        final success = await notifier.cancelEvent();

        expect(success, isTrue);
        expect(notifier.state.event?.status, EventStatus.cancelled);
        expect(notifier.state.event?.isCancelled, isTrue);
        expect(notifier.state.cancellationSucceeded, isTrue);
        expect(notifier.state.isCancelling, isFalse);
        expect(notifier.canCancelEvent, isFalse);
      });

      test(
        'bloquea la cancelación si el usuario no es el organizador',
        () async {
          final repo = FakeEventsRepository(
            delay: Duration.zero,
            initialEvents: [testEvent],
          );
          final notifier = EventDetailNotifier(
            repository: repo,
            currentSession: guestSession,
            eventId: testEventId,
            initialEvent: testEvent,
          );

          final success = await notifier.cancelEvent();

          expect(success, isFalse);
          expect(notifier.state.event?.status, EventStatus.active);
          expect(notifier.state.cancellationFailed, isTrue);
        },
      );

      test(
        'maneja error del repositorio sin romper el estado del evento',
        () async {
          final repo = FakeEventsRepository(
            delay: Duration.zero,
            shouldFailCancellation: true,
            initialEvents: [testEvent],
          );
          final notifier = EventDetailNotifier(
            repository: repo,
            currentSession: organizerSession,
            eventId: testEventId,
            initialEvent: testEvent,
          );

          final success = await notifier.cancelEvent();

          expect(success, isFalse);
          expect(notifier.state.event?.status, EventStatus.active);
          expect(notifier.state.isCancelling, isFalse);
          expect(notifier.state.cancellationFailed, isTrue);
          expect(notifier.state.cancellationSucceeded, isFalse);
        },
      );

      test('resetCancellationStatus limpia el estado de cancelación', () {
        final repo = FakeEventsRepository(delay: Duration.zero);
        final notifier = EventDetailNotifier(
          repository: repo,
          currentSession: organizerSession,
          eventId: testEventId,
          initialEvent: testEvent,
        );

        notifier.state = notifier.state.copyWith(
          cancellationStatus: EventCancellationStatus.failure,
        );
        expect(notifier.state.cancellationFailed, isTrue);

        notifier.resetCancellationStatus();
        expect(notifier.state.cancellationStatus, EventCancellationStatus.idle);
      });
    });
  });
}
