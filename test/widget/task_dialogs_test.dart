import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/events/domain/event_participant.dart';
import 'package:planify/features/tasks/presentation/widgets/create_task_dialog.dart';
import 'package:planify/features/tasks/presentation/widgets/reassign_task_dialog.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: Scaffold(body: child),
    );
  }

  const participants = [
    EventParticipant(
      id: 'participant-lucia',
      eventId: 'event-1',
      userId: 'user-lucia',
      username: 'Lucía',
      isAnonymous: false,
      isOrganizer: true,
    ),
    EventParticipant(
      id: 'participant-juan',
      eventId: 'event-1',
      userId: null,
      username: 'Juan',
      isAnonymous: true,
      isOrganizer: false,
    ),
  ];

  testWidgets('crear tarea valida el título y entrega el texto normalizado', (
    tester,
  ) async {
    String? submittedTitle;
    await tester.pumpWidget(
      buildSubject(
        CreateTaskDialog(
          onCreate: (title) async {
            submittedTitle = title;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('create_task_submit_button')));
    await tester.pump();
    expect(find.text('Ingresá un título para la tarea.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('create_task_title_field')),
      '  Comprar carbón  ',
    );
    await tester.tap(find.byKey(const Key('create_task_submit_button')));
    await tester.pumpAndSettle();

    expect(submittedTitle, 'Comprar carbón');
  });

  testWidgets('reasignar exige una persona y envía su participantId', (
    tester,
  ) async {
    String? assignedParticipantId;
    await tester.pumpWidget(
      buildSubject(
        ReassignTaskDialog(
          participants: participants,
          onAssign: (participantId) async {
            assignedParticipantId = participantId;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('reassign_task_submit_button')));
    await tester.pump();
    expect(find.text('Elegí una persona para continuar.'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('reassign_task_participant_participant-juan')),
    );
    await tester.tap(find.byKey(const Key('reassign_task_submit_button')));
    await tester.pumpAndSettle();

    expect(assignedParticipantId, 'participant-juan');
  });

  testWidgets(
    'reasignar permite recorrer una lista larga sin ocultar la confirmación',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final manyParticipants = List.generate(
        20,
        (index) => EventParticipant(
          id: 'participant-$index',
          eventId: 'event-1',
          userId: 'user-$index',
          username: 'Participante $index',
          isAnonymous: false,
          isOrganizer: index == 0,
        ),
      );
      String? assignedParticipantId;

      await tester.pumpWidget(
        buildSubject(
          ReassignTaskDialog(
            participants: manyParticipants,
            onAssign: (participantId) async {
              assignedParticipantId = participantId;
              return true;
            },
          ),
        ),
      );

      final list = find.byKey(const Key('reassign_task_participants_list'));
      final scrollable = find.descendant(
        of: list,
        matching: find.byType(Scrollable),
      );
      final lastParticipant = find.byKey(
        const Key('reassign_task_participant_participant-19'),
      );
      expect(list, findsOneWidget);
      expect(scrollable, findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        lastParticipant,
        200,
        scrollable: scrollable,
      );
      await tester.tap(lastParticipant);
      await tester.tap(find.byKey(const Key('reassign_task_submit_button')));
      await tester.pumpAndSettle();

      expect(assignedParticipantId, 'participant-19');
    },
  );
}
