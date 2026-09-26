import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/debts/data/fake_debts_repository.dart';
import 'package:planify/features/debts/domain/debts_repository.dart';
import 'package:planify/features/debts/domain/event_debts.dart';
import 'package:planify/features/debts/presentation/controllers/debts_providers.dart';
import 'package:planify/features/debts/presentation/widgets/event_debts_card.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  Widget buildCard({
    required DebtsRepository repository,
    required String eventId,
  }) {
    return ProviderScope(
      overrides: [debtsRepositoryProvider.overrideWithValue(repository)],
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
        home: Scaffold(body: EventDebtsCard(eventId: eventId)),
      ),
    );
  }

  group('EventDebtsCard', () {
    testWidgets('muestra deudas, montos y ambos estados', (tester) async {
      await tester.pumpWidget(
        buildCard(
          repository: FakeDebtsRepository(delay: Duration.zero),
          eventId: 'evt-123',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_debts_card')), findsOneWidget);
      expect(find.textContaining('Ana le debe'), findsNWidgets(2));
      expect(find.textContaining(r'$ 500,00'), findsOneWidget);
      expect(find.text('Pendiente'), findsNWidgets(2));
      expect(find.text('Saldada'), findsOneWidget);
    });

    testWidgets('muestra el estado vacío', (tester) async {
      await tester.pumpWidget(
        buildCard(
          repository: FakeDebtsRepository(delay: Duration.zero),
          eventId: 'evt-fake-demo',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_debts_empty')), findsOneWidget);
      expect(
        find.byKey(const Key('event_debts_feedback_icon_container')),
        findsOneWidget,
      );
      expect(
        find.text('Todavía no hay deudas en este evento.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra la etiqueta Todo saldado', (tester) async {
      await tester.pumpWidget(
        buildCard(
          repository: FakeDebtsRepository(delay: Duration.zero),
          eventId: 'evt-cumple-lucas',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_debts_all_settled')), findsOneWidget);
      expect(find.text('Todo saldado'), findsOneWidget);
    });

    testWidgets('muestra error y permite reintentar', (tester) async {
      final repository = FakeDebtsRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      );
      await tester.pumpWidget(
        buildCard(repository: repository, eventId: 'evt-123'),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_debts_error')), findsOneWidget);
      expect(find.byKey(const Key('event_debts_retry_button')), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      repository.shouldThrowError = false;
      await tester.tap(find.byKey(const Key('event_debts_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_debts_error')), findsNothing);
      expect(
        find.byKey(const Key('event_debt_row_debt-evt-123-1')),
        findsOneWidget,
      );
    });

    testWidgets('muestra loading mientras la respuesta sigue pendiente', (
      tester,
    ) async {
      final repository = _ControlledDebtsRepository();
      await tester.pumpWidget(
        buildCard(repository: repository, eventId: 'evt-123'),
      );

      expect(find.byKey(const Key('event_debts_loading')), findsOneWidget);

      repository.complete(const EventDebts(debts: [], allSettled: false));
      await tester.pump();
      await tester.pump();
    });
  });
}

class _ControlledDebtsRepository implements DebtsRepository {
  final _completer = Completer<EventDebts>();

  @override
  Future<EventDebts> listEventDebts(String eventId) => _completer.future;

  void complete(EventDebts eventDebts) => _completer.complete(eventDebts);
}
