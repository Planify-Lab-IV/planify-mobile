import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/events/domain/event_participant.dart';
import 'package:planify/features/expenses/domain/expense_payer_draft.dart';
import 'package:planify/features/expenses/presentation/widgets/expense_payer_amounts.dart';
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
    required List<ExpensePayerDraft> payerDrafts,
    required int differenceCents,
    required void Function(String, int?) onPayerAmountChanged,
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
        body: ExpensePayerAmounts(
          participants: participants,
          payerDrafts: payerDrafts,
          differenceCents: differenceCents,
          onPayerAmountChanged: onPayerAmountChanged,
          onSplitEvenly: onSplitEvenly,
        ),
      ),
    );
  }

  testWidgets('un solo pagador ve el total bloqueado', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        payerDrafts: const [
          ExpensePayerDraft(
            participantId: 'participant-lucia',
            amountCents: 1250,
          ),
        ],
        differenceCents: 0,
        onPayerAmountChanged: (_, _) {},
        onSplitEvenly: () {},
      ),
    );

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('expense_payer_amount_participant-lucia')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.readOnly, isTrue);
    expect(find.text('12,50'), findsOneWidget);
    expect(find.byKey(const Key('expense_split_evenly_button')), findsNothing);
  });

  testWidgets('varios pagadores editan importes, reparten y ven el desvío', (
    tester,
  ) async {
    String? changedParticipant;
    int? changedAmount;
    var didSplitEvenly = false;

    await tester.pumpWidget(
      buildSubject(
        payerDrafts: const [
          ExpensePayerDraft(
            participantId: 'participant-lucia',
            amountCents: 400,
          ),
          ExpensePayerDraft(
            participantId: 'participant-juan',
            amountCents: 400,
          ),
        ],
        differenceCents: 200,
        onPayerAmountChanged: (participantId, amountCents) {
          changedParticipant = participantId;
          changedAmount = amountCents;
        },
        onSplitEvenly: () => didSplitEvenly = true,
      ),
    );

    final luciaField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('expense_payer_amount_participant-lucia')),
        matching: find.byType(TextField),
      ),
    );
    expect(luciaField.readOnly, isFalse);
    expect(
      find.text(r'Faltan $ 2,00 para completar el total.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('expense_payer_amount_participant-lucia')),
      '5,50',
    );
    await tester.pump();
    expect(changedParticipant, 'participant-lucia');
    expect(changedAmount, 550);

    await tester.tap(find.byKey(const Key('expense_split_evenly_button')));
    await tester.pump();
    expect(didSplitEvenly, isTrue);
  });
}
