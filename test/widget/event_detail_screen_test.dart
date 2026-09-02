import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/domain/event.dart';
import 'package:planify/features/events/domain/event_status.dart';
import 'package:planify/features/events/presentation/controllers/event_detail_notifier.dart';
import 'package:planify/features/events/presentation/controllers/events_providers.dart';
import 'package:planify/features/events/presentation/screens/event_detail_screen.dart';
import 'package:planify/features/events/presentation/widgets/cancel_event_dialog.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  group('EventDetailScreen Widget Tests', () {
    const testOrganizerId = 'org-123';
    const testEventId = 'evt-test-123';

    const testEvent = Event(
      id: testEventId,
      name: 'Cumpleaños de Lucas',
      location: 'Av. Corrientes 1234',
      organizerId: testOrganizerId,
      status: EventStatus.active,
      date: 'Sábado 15 de Noviembre, 21:00 hs',
    );

    const organizerSession = OrganizerSession(
      userId: testOrganizerId,
      email: 'lucas@planify.com',
      name: 'Lucas',
      token: 'fake-token',
    );

    const otherOrganizerSession = OrganizerSession(
      userId: 'org-999',
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

    Widget buildDetailScreen({
      required UserSession? session,
      FakeEventsRepository? customRepo,
      String eventId = testEventId,
    }) {
      final repository =
          customRepo ??
          FakeEventsRepository(
            delay: Duration.zero,
            initialEvents: [testEvent],
          );

      return ProviderScope(
        overrides: [
          eventsRepositoryProvider.overrideWithValue(repository),
          authNotifierProvider.overrideWith((ref) {
            final authNotifier = ref.watch(authNotifierProvider.notifier);
            return authNotifier;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: EventDetailScreenWithSession(
            session: session,
            eventId: eventId,
            repository: repository,
          ),
        ),
      );
    }

    testWidgets(
      'renderiza header, acciones rápidas, tareas vacías y actividad vacía',
      (tester) async {
        await tester.pumpWidget(buildDetailScreen(session: organizerSession));
        await tester.pumpAndSettle();

        // Título del AppBar
        expect(find.text('Detalle del evento'), findsOneWidget);

        // Header
        expect(find.byKey(const Key('event_detail_name')), findsOneWidget);
        expect(find.text('Cumpleaños de Lucas'), findsOneWidget);
        expect(find.text('Av. Corrientes 1234'), findsOneWidget);
        expect(find.text('Sábado 15 de Noviembre, 21:00 hs'), findsOneWidget);
        expect(find.text('Activo'), findsOneWidget);

        // Acciones rápidas (4 botones)
        expect(find.text('Acciones rápidas'), findsOneWidget);
        expect(find.byKey(const Key('quick_action_invite')), findsOneWidget);
        expect(
          find.byKey(const Key('quick_action_add_expense')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('quick_action_add_task')), findsOneWidget);
        expect(find.byKey(const Key('quick_action_settle')), findsOneWidget);
        expect(find.text('Invitar'), findsOneWidget);
        expect(find.text('Agregar gasto'), findsOneWidget);
        expect(find.text('Agregar tarea'), findsOneWidget);
        expect(find.text('Saldar'), findsOneWidget);

        // Tareas y Actividad vacías
        expect(find.text('Tareas'), findsOneWidget);
        expect(find.text('No hay tareas asignadas todavía.'), findsOneWidget);
        expect(find.text('Actividad reciente'), findsOneWidget);
        expect(
          find.text('Sin actividad registrada en este evento.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'acciones rápidas muestran feedback de funcionalidad en desarrollo',
      (tester) async {
        await tester.pumpWidget(buildDetailScreen(session: organizerSession));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('quick_action_invite')));
        await tester.pumpAndSettle();
        expect(
          find.text('Esta funcionalidad estará disponible próximamente.'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('quick_action_add_expense')));
        await tester.pumpAndSettle();
        expect(
          find.text('Esta funcionalidad estará disponible próximamente.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'organizador del evento ve la opción Cancelar evento en menú y botón',
      (tester) async {
        await tester.pumpWidget(buildDetailScreen(session: organizerSession));
        await tester.pumpAndSettle();

        // Botón en AppBar y botón al pie de página
        expect(
          find.byKey(const Key('event_actions_menu_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('cancel_event_button')), findsOneWidget);
      },
    );

    testWidgets('invitado del evento NO ve la opción Cancelar evento', (
      tester,
    ) async {
      await tester.pumpWidget(buildDetailScreen(session: guestSession));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_actions_menu_button')), findsNothing);
      expect(find.byKey(const Key('cancel_event_button')), findsNothing);
      expect(find.text('Cancelar evento'), findsNothing);
    });

    testWidgets('organizador de OTRO evento NO ve la opción Cancelar evento', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildDetailScreen(session: otherOrganizerSession),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_actions_menu_button')), findsNothing);
      expect(find.byKey(const Key('cancel_event_button')), findsNothing);
      expect(find.text('Cancelar evento'), findsNothing);
    });

    testWidgets('flujo completo de confirmación y cancelación exitosa', (
      tester,
    ) async {
      final repo = FakeEventsRepository(
        delay: Duration.zero,
        initialEvents: [testEvent],
      );

      await tester.pumpWidget(
        buildDetailScreen(session: organizerSession, customRepo: repo),
      );
      await tester.pumpAndSettle();

      // 1. Toca cancelar evento desde el botón inferior
      await tester.ensureVisible(find.byKey(const Key('cancel_event_button')));
      await tester.tap(find.byKey(const Key('cancel_event_button')));
      await tester.pumpAndSettle();

      // 2. Se despliega el diálogo de confirmación
      expect(find.byType(CancelEventDialog), findsOneWidget);
      expect(find.text('¿Cancelar evento?'), findsOneWidget);
      expect(
        find.text(
          '¿Estás seguro de que querés cancelar este evento? Esta acción no se puede deshacer.',
        ),
        findsOneWidget,
      );

      // 3. Confirmar cancelación
      await tester.tap(find.byKey(const Key('cancel_dialog_confirm_button')));
      await tester.pumpAndSettle();

      // 4. Se refleja el estado Cancelado
      expect(find.text('Cancelado'), findsOneWidget);
      expect(
        find.text(
          'Este evento ha sido cancelado y ya no acepta nuevas acciones.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('El evento fue cancelado correctamente.'),
        findsOneWidget,
      );

      // 5. Las opciones de cancelación ya no se muestran
      expect(find.byKey(const Key('cancel_event_button')), findsNothing);
      expect(find.byKey(const Key('event_actions_menu_button')), findsNothing);

      // 6. El repositorio en memoria cambió a cancelled
      final eventInRepo = await repo.getEvent(testEventId);
      expect(eventInRepo?.isCancelled, isTrue);
    });

    testWidgets(
      'cancelación desde el PopupMenu del AppBar también ejecuta el diálogo',
      (tester) async {
        final repo = FakeEventsRepository(
          delay: Duration.zero,
          initialEvents: [testEvent],
        );

        await tester.pumpWidget(
          buildDetailScreen(session: organizerSession, customRepo: repo),
        );
        await tester.pumpAndSettle();

        // Abrir menú de acciones del AppBar
        await tester.tap(find.byKey(const Key('event_actions_menu_button')));
        await tester.pumpAndSettle();

        // Tocar opción Cancelar evento en el menú
        expect(find.byKey(const Key('cancel_event_menu_item')), findsOneWidget);
        await tester.tap(find.byKey(const Key('cancel_event_menu_item')));
        await tester.pumpAndSettle();

        // Diálogo abierto
        expect(find.byType(CancelEventDialog), findsOneWidget);

        // Descartar diálogo (Volver)
        await tester.tap(find.byKey(const Key('cancel_dialog_dismiss_button')));
        await tester.pumpAndSettle();

        // El diálogo se cierra y el evento sigue Activo
        expect(find.byType(CancelEventDialog), findsNothing);
        expect(find.text('Activo'), findsOneWidget);
      },
    );

    testWidgets(
      'maneja error de cancelación mostrando SnackBar y permitiendo reintentar',
      (tester) async {
        final repo = FakeEventsRepository(
          delay: Duration.zero,
          shouldFailCancellation: true,
          initialEvents: [testEvent],
        );

        await tester.pumpWidget(
          buildDetailScreen(session: organizerSession, customRepo: repo),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('cancel_event_button')),
        );
        await tester.tap(find.byKey(const Key('cancel_event_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('cancel_dialog_confirm_button')));
        await tester.pumpAndSettle();

        // El diálogo se cierra y se muestra SnackBar de error con Reintentar
        expect(find.byType(CancelEventDialog), findsNothing);
        expect(find.text('No se pudo cancelar el evento'), findsOneWidget);
        expect(find.text('Reintentar'), findsOneWidget);
        expect(find.text('Activo'), findsOneWidget);
      },
    );
  });
}

/// Helper para sobreescribir la sesión en tests sin acoplar a ProviderScope global
class EventDetailScreenWithSession extends ConsumerWidget {
  final UserSession? session;
  final String eventId;
  final FakeEventsRepository repository;

  const EventDetailScreenWithSession({
    super.key,
    required this.session,
    required this.eventId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        eventDetailNotifierProvider(eventId).overrideWith((ref) {
          return EventDetailNotifier(
            repository: repository,
            currentSession: session,
            eventId: eventId,
          );
        }),
      ],
      child: EventDetailScreen(eventId: eventId),
    );
  }
}
