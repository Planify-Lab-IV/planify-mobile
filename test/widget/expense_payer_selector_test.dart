import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/events/domain/event_participant.dart';
import 'package:planify/features/expenses/presentation/widgets/expense_payer_selector.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
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

  Widget buildSubject(ValueChanged<String> onParticipantToggled) {
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
      home: Scaffold(
        body: ExpensePayerSelector(
          participants: participants,
          selectedParticipantIds: const {'participant-lucia'},
          onParticipantToggled: onParticipantToggled,
        ),
      ),
    );
  }

  testWidgets('muestra un selector por participante, sin campos de monto', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject((_) {}));

    expect(find.text('¿Quiénes pagaron?'), findsOneWidget);
    expect(find.text('Lucía'), findsOneWidget);
    expect(find.text('Juan'), findsOneWidget);
    expect(
      find.byKey(const Key('expense_payer_selector_participant-lucia')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('expense_payer_selector_participant-juan')),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('comunica el identificador del participante tocado', (
    tester,
  ) async {
    String? toggledParticipantId;
    await tester.pumpWidget(
      buildSubject((participantId) => toggledParticipantId = participantId),
    );

    await tester.tap(
      find.byKey(const Key('expense_payer_selector_participant-juan')),
    );
    await tester.pump();

    expect(toggledParticipantId, 'participant-juan');
  });
}
