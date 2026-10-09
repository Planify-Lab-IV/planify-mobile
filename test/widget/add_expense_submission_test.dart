import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/events/domain/event_participant.dart';
import 'package:planify/features/expenses/data/expenses_exceptions.dart';
import 'package:planify/features/expenses/data/fake_expenses_repository.dart';
import 'package:planify/features/expenses/domain/expense.dart';
import 'package:planify/features/expenses/domain/new_expense.dart';
import 'package:planify/features/expenses/presentation/controllers/expenses_providers.dart';
import 'package:planify/features/expenses/presentation/widgets/add_expense_dialog.dart';
import 'package:planify/l10n/app_localizations.dart';

class PendingRepository extends FakeExpensesRepository {
  final pending = Completer<void>();
  final ExpensesException? failure;
  final requests = <NewExpense>[];
  int calls = 0;
  PendingRepository({this.failure}) : super(delay: Duration.zero);
  @override
  Future<Expense> createExpense(String eventId, NewExpense expense) async {
    calls++;
    requests.add(expense);
    if (calls == 1) {
      await pending.future;
      if (failure != null) throw failure!;
    }
    return super.createExpense(eventId, expense);
  }
}

void main() {
  const participants = [
    EventParticipant(
      id: 'p1',
      eventId: 'event-1',
      userId: 'u1',
      username: 'Lucía',
      isAnonymous: false,
      isOrganizer: true,
    ),
  ];

  Future<void> open(
    WidgetTester tester,
    FakeExpensesRepository repository,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [expensesRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AddExpenseDialog.show(
                  context,
                  eventId: 'event-1',
                  participants: participants,
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('expense_description_field')),
      'Cena',
    );
    await tester.enterText(
      find.byKey(const Key('expense_total_field')),
      '100,00',
    );
    for (final key in [
      'expense_payer_selector_p1',
      'expense_debtor_selector_p1',
    ]) {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.tap(find.byKey(Key(key)));
      await tester.pump();
    }
  }

  final confirm = find.byKey(const Key('add_expense_save_button'));

  testWidgets('valid form submits once, disables close and reports success', (
    tester,
  ) async {
    final repository = PendingRepository();
    await open(tester, repository);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await fill(tester);
    await tester.tap(confirm);
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('add_expense_dialog_close_button')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(confirm);
    expect(repository.calls, 1);
    repository.pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AddExpenseDialog), findsNothing);
    expect(find.text('El gasto se guardó correctamente.'), findsOneWidget);
    expect(repository.expenses.single.totalAmountCents, 10000);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
  });

  testWidgets('failure preserves input and Retry is tappable above the sheet', (
    tester,
  ) async {
    final repository = PendingRepository(
      failure: const NetworkExpenseException(),
    );
    await open(tester, repository);
    await fill(tester);
    await tester.tap(confirm);
    await tester.pump();
    repository.pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AddExpenseDialog), findsOneWidget);
    expect(find.text('Cena'), findsOneWidget);
    expect(
      find.text('No se pudo guardar el gasto por un problema de conexión.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.byType(AddExpenseDialog), findsNothing);
    expect(find.text('El gasto se guardó correctamente.'), findsOneWidget);
  });

  testWidgets('dragging while saving keeps the failed form and its Retry', (
    tester,
  ) async {
    final repository = PendingRepository(
      failure: const NetworkExpenseException(),
    );
    await open(tester, repository);
    await fill(tester);
    await tester.tap(confirm);
    await tester.pump();

    await tester.dragFrom(const Offset(400, 120), const Offset(0, 500));
    await tester.pump();
    expect(find.byType(AddExpenseDialog), findsOneWidget);

    repository.pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AddExpenseDialog), findsOneWidget);
    expect(find.text('Reintentar').hitTestable(), findsOneWidget);
  });

  testWidgets(
    'saving disables focused fields and retries the displayed draft',
    (tester) async {
      final repository = PendingRepository(
        failure: const NetworkExpenseException(),
      );
      final description = find.byKey(const Key('expense_description_field'));
      await open(tester, repository);
      await fill(tester);
      await tester.tap(description);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: description,
                matching: find.byType(EditableText),
              ),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );

      await tester.tap(confirm);
      await tester.pump();
      expect(tester.widget<TextFormField>(description).enabled, isFalse);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: description,
                matching: find.byType(EditableText),
              ),
            )
            .focusNode
            .hasFocus,
        isFalse,
      );

      repository.pending.complete();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(description).controller?.text,
        'Cena',
      );

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(repository.requests.last.description, 'Cena');
    },
  );

  testWidgets('closing a failed form removes its Retry action', (tester) async {
    final repository = PendingRepository(
      failure: const ExpenseValidationException(),
    );
    await open(tester, repository);
    await fill(tester);
    await tester.tap(confirm);
    await tester.pump();
    repository.pending.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_expense_dialog_close_button')));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsNothing);
    expect(repository.calls, 1);
    expect(tester.takeException(), isNull);
  });
}
