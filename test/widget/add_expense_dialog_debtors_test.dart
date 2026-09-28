import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/events/domain/event_participant.dart';
import 'package:planify/features/expenses/presentation/widgets/add_expense_dialog.dart';
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

  Widget buildSubject() {
    return ProviderScope(
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
        home: const Scaffold(
          body: AddExpenseDialog(participants: participants),
        ),
      ),
    );
  }

  testWidgets('muestra ambas selecciones antes que los montos de cada rol', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    final payersTitle = find.text('¿Quiénes pagaron?');
    final debtorsTitle = find.text('¿Quiénes deben?');
    expect(payersTitle, findsOneWidget);
    expect(debtorsTitle, findsOneWidget);
    expect(
      tester.getTopLeft(payersTitle).dy,
      lessThan(tester.getTopLeft(debtorsTitle).dy),
    );

    await tester.enterText(
      find.byKey(const Key('expense_total_field')),
      '10,00',
    );
    await tester.ensureVisible(
      find.byKey(const Key('expense_payer_selector_participant-lucia')),
    );
    await tester.tap(
      find.byKey(const Key('expense_payer_selector_participant-lucia')),
    );
    await tester.ensureVisible(
      find.byKey(const Key('expense_debtor_selector_participant-lucia')),
    );
    await tester.tap(
      find.byKey(const Key('expense_debtor_selector_participant-lucia')),
    );
    await tester.pump();

    final payerAmountsTitle = find.text('Montos pagados');
    final debtorAmountsTitle = find.text('Montos adeudados');
    expect(payerAmountsTitle, findsOneWidget);
    expect(debtorAmountsTitle, findsOneWidget);
    expect(
      tester.getTopLeft(debtorsTitle).dy,
      lessThan(tester.getTopLeft(payerAmountsTitle).dy),
    );
    expect(
      tester.getTopLeft(payerAmountsTitle).dy,
      lessThan(tester.getTopLeft(debtorAmountsTitle).dy),
    );
    expect(
      find.byKey(const Key('expense_payer_amount_participant-lucia')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('expense_debtor_amount_participant-lucia')),
      findsOneWidget,
    );
  });
}
