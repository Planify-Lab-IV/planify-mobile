import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/detail/controllers/event_detail_notifier.dart';
import 'package:planify/features/events/detail/controllers/events_providers.dart';
import 'package:planify/features/events/domain/event.dart';
import 'package:planify/features/events/domain/event_participant.dart';
import 'package:planify/features/events/domain/event_status.dart';
import 'package:planify/features/tasks/data/fake_tasks_repository.dart';
import 'package:planify/features/tasks/domain/task.dart';
import 'package:planify/features/tasks/domain/task_status.dart';
import 'package:planify/features/tasks/presentation/controllers/tasks_context.dart';
import 'package:planify/features/tasks/presentation/controllers/tasks_providers.dart';
import 'package:planify/features/tasks/presentation/widgets/task_list_card.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  const eventId = 'event-1';
  const luciaId = 'participant-lucia';
  const juanId = 'participant-juan';
  const lucia = EventParticipant(
    id: luciaId,
    eventId: eventId,
    userId: 'user-lucia',
    username: 'Lucía',
    isAnonymous: false,
    isOrganizer: true,
  );
  const juan = EventParticipant(
    id: juanId,
    eventId: eventId,
    userId: null,
    username: 'Juan',
    isAnonymous: true,
    isOrganizer: false,
  );
  final event = Event(
    id: eventId,
    name: 'Asado',
    location: 'Club',
    organizerId: 'user-lucia',
    groupId: 'group-1',
    status: EventStatus.active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    participants: const [lucia, juan],
  );
  const organizerSession = OrganizerSession(
    userId: 'user-lucia',
    email: 'lucia@example.com',
    name: 'Lucía',
    username: 'lucia',
    token: 'token',
  );
  const guestSession = AnonymousSession(
    participantId: juanId,
    name: 'Juan',
    eventId: eventId,
    token: 'token',
  );

  Widget buildSubject({
    required UserSession session,
    required List<Task> tasks,
  }) {
    final repository = FakeEventsRepository(
      delay: Duration.zero,
      initialEvents: [event],
    );
    final actorId = session is AnonymousSession
        ? session.participantId
        : luciaId;
    final tasksRepository = FakeTasksRepository(
      delay: Duration.zero,
      initialTasks: tasks,
      currentParticipantIdForEvent: (_) => actorId,
    );
    final tasksContext = TasksContext(
      eventId: eventId,
      currentParticipantId: actorId,
      isOrganizer: session is OrganizerSession,
      participants: const [lucia, juan],
    );

    return ProviderScope(
      overrides: [
        eventDetailNotifierProvider(eventId).overrideWith(
          (ref) => EventDetailNotifier(
            repository: repository,
            currentSession: session,
            eventId: eventId,
            initialEvent: event,
          ),
        ),
        tasksRepositoryProvider(actorId).overrideWithValue(tasksRepository),
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
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TaskListCard(
              participants: [lucia, juan],
              tasksContext: tasksContext,
            ),
          ),
        ),
      ),
    );
  }

  const tasks = [
    Task(
      id: 'task-unassigned',
      eventId: eventId,
      title: 'Comprar hielo',
      status: TaskStatus.unassigned,
      assignedToParticipantId: null,
      createdByParticipantId: luciaId,
    ),
    Task(
      id: 'task-lucia',
      eventId: eventId,
      title: 'Preparar ensalada',
      status: TaskStatus.pending,
      assignedToParticipantId: luciaId,
      createdByParticipantId: juanId,
    ),
    Task(
      id: 'task-juan',
      eventId: eventId,
      title: 'Reservar salón',
      status: TaskStatus.pending,
      assignedToParticipantId: juanId,
      createdByParticipantId: luciaId,
    ),
    Task(
      id: 'task-completed',
      eventId: eventId,
      title: 'Enviar invitaciones',
      status: TaskStatus.completed,
      assignedToParticipantId: juanId,
      createdByParticipantId: luciaId,
    ),
  ];

  testWidgets('muestra los tres estados y acciones correctas del organizador', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(session: organizerSession, tasks: tasks),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin asignar'), findsOneWidget);
    expect(find.text('Pendiente'), findsNWidgets(2));
    expect(find.text('Completada'), findsOneWidget);
    expect(
      find.byKey(const Key('task_claim_button_task-unassigned')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('task_complete_button_task-lucia')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('task_reassign_button_task-juan')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('task_reassign_button_task-lucia')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('task_claim_button_task-completed')),
      findsNothing,
    );
  });

  testWidgets('un invitado no puede reasignar una tarea ajena', (tester) async {
    await tester.pumpWidget(buildSubject(session: guestSession, tasks: tasks));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('task_claim_button_task-unassigned')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('task_complete_button_task-juan')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('task_reassign_button_task-lucia')),
      findsNothing,
    );
  });

  testWidgets('tomar una tarea actualiza su estado y responsable', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(session: organizerSession, tasks: tasks),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('task_claim_button_task-unassigned')),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('task_row_task-unassigned')),
        matching: find.text('Asignada a Lucía'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('task_complete_button_task-unassigned')),
      findsOneWidget,
    );
  });
}
