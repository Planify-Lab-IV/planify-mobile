import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/events/domain/event_participant.dart';
import 'package:planify/features/expenses/domain/expense_debtor_draft.dart';
import 'package:planify/features/expenses/presentation/widgets/expense_debtor_amounts.dart';
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

  Widget buildSubject({
    required List<ExpenseDebtorDraft> debtorDrafts,
    required int differenceCents,
    required void Function(String, int?) onDebtorAmountChanged,
    required VoidCallback onSplitEvenly,
  }) {
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
        body: ExpenseDebtorAmounts(
          participants: participants,
          debtorDrafts: debtorDrafts,
          differenceCents: differenceCents,
          onDebtorAmountChanged: onDebtorAmountChanged,
          onSplitEvenly: onSplitEvenly,
        ),
      ),
    );
  }

  testWidgets('un solo deudor ve el total bloqueado', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        debtorDrafts: const [
          ExpenseDebtorDraft(
            participantId: 'participant-lucia',
            amountCents: 1250,
          ),
        ],
        differenceCents: 0,
        onDebtorAmountChanged: (_, _) {},
        onSplitEvenly: () {},
      ),
    );

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('expense_debtor_amount_participant-lucia')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.readOnly, isTrue);
    expect(find.text('12,50'), findsOneWidget);
    expect(
      find.byKey(const Key('expense_debtor_split_evenly_button')),
      findsNothing,
    );
  });

  testWidgets('varios deudores editan importes, reparten y ven el desvío', (
    tester,
  ) async {
    String? changedParticipant;
    int? changedAmount;
    var didSplitEvenly = false;

    await tester.pumpWidget(
      buildSubject(
        debtorDrafts: const [
          ExpenseDebtorDraft(
            participantId: 'participant-lucia',
            amountCents: 400,
          ),
          ExpenseDebtorDraft(
            participantId: 'participant-juan',
            amountCents: 400,
          ),
        ],
        differenceCents: 200,
        onDebtorAmountChanged: (participantId, amountCents) {
          changedParticipant = participantId;
          changedAmount = amountCents;
        },
        onSplitEvenly: () => didSplitEvenly = true,
      ),
    );

    final luciaField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('expense_debtor_amount_participant-lucia')),
        matching: find.byType(TextField),
      ),
    );
    expect(luciaField.readOnly, isFalse);
    expect(
      find.text(r'Faltan $ 2,00 para completar el total.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('expense_debtor_amount_participant-lucia')),
      '5,50',
    );
    await tester.pump();
    expect(changedParticipant, 'participant-lucia');
    expect(changedAmount, 550);

    await tester.tap(
      find.byKey(const Key('expense_debtor_split_evenly_button')),
    );
    await tester.pump();
    expect(didSplitEvenly, isTrue);
  });
}
