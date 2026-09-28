import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/balances/data/fake_balances_repository.dart';
import 'package:planify/features/balances/domain/balance_summary.dart';
import 'package:planify/features/balances/domain/balances_repository.dart';
import 'package:planify/features/balances/domain/person_balance.dart';
import 'package:planify/features/balances/domain/person_balance_status.dart';
import 'package:planify/features/balances/presentation/controllers/balances_providers.dart';
import 'package:planify/features/balances/presentation/screens/balances_screen.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  Widget buildScreen({
    required BalancesRepository repository,
    ValueChanged<String>? onPersonTap,
  }) {
    return ProviderScope(
      overrides: [balancesRepositoryProvider.overrideWithValue(repository)],
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
        home: BalancesScreen(onPersonTap: onPersonTap),
      ),
    );
  }

  group('BalancesScreen', () {
    testWidgets('muestra resumen, personas, montos y los tres estados', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildScreen(repository: FakeBalancesRepository(delay: Duration.zero)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('balance_summary_card')), findsOneWidget);
      expect(find.byKey(const Key('balance_owed_to_me')), findsOneWidget);
      expect(find.byKey(const Key('balance_i_owe')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('balance_owed_to_me')),
          matching: find.text('Me deben'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('balance_i_owe')),
          matching: find.text('Debo'),
        ),
        findsOneWidget,
      );
      expect(find.text('Balance neto'), findsOneWidget);
      expect(find.text(r'+$ 582,00'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('balance_owed_to_me')),
          matching: find.text(r'$ 825,00'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('balance_i_owe')),
          matching: find.text(r'$ 243,00'),
        ),
        findsOneWidget,
      );
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('A pagar'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Saldado'), findsOneWidget);
    });

    testWidgets('filtra las personas entre Todo, Me deben y Debo', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildScreen(repository: FakeBalancesRepository(delay: Duration.zero)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('balance_filter_i_owe')));
      await tester.pumpAndSettle();

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Martín'), findsNothing);
      expect(find.text('Sol'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('balance_person_user:ana')),
          matching: find.text(r'$ 243,00'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('balance_filter_owed_to_me')));
      await tester.pumpAndSettle();

      expect(find.text('Ana'), findsNothing);
      expect(find.text('Martín'), findsOneWidget);
      expect(find.text('Sol'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('balance_person_participant:martin')),
          matching: find.text(r'$ 825,00'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('balance_filter_all')));
      await tester.pumpAndSettle();

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Martín'), findsOneWidget);
      expect(find.text('Sol'), findsOneWidget);
    });

    testWidgets('propaga personKey al tocar una fila', (tester) async {
      String? tappedPersonKey;
      await tester.pumpWidget(
        buildScreen(
          repository: FakeBalancesRepository(delay: Duration.zero),
          onPersonTap: (personKey) => tappedPersonKey = personKey,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('balance_person_user:ana')));

      expect(tappedPersonKey, 'user:ana');
    });

    testWidgets('muestra el aviso temporal al tocar una persona sin detalle', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildScreen(repository: FakeBalancesRepository(delay: Duration.zero)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('balance_person_user:ana')));
      await tester.pump();

      expect(
        find.text('Esta funcionalidad estará disponible próximamente.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra el estado vacío', (tester) async {
      await tester.pumpWidget(
        buildScreen(
          repository: FakeBalancesRepository(
            delay: Duration.zero,
            initialSummary: const BalanceSummary(
              owedToMeCents: 0,
              iOweCents: 0,
            ),
            initialPeople: const [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('balances_empty')), findsOneWidget);
      expect(find.text('No tenés saldos pendientes.'), findsOneWidget);
    });

    testWidgets('muestra error y permite reintentar', (tester) async {
      final repository = FakeBalancesRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      );
      await tester.pumpWidget(buildScreen(repository: repository));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('balances_error')), findsOneWidget);
      expect(find.byKey(const Key('balances_retry_button')), findsOneWidget);

      repository.shouldThrowError = false;
      await tester.tap(find.byKey(const Key('balances_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('balances_error')), findsNothing);
      expect(find.byKey(const Key('balance_summary_card')), findsOneWidget);
    });

    testWidgets('muestra carga hasta que resumen y personas estén listos', (
      tester,
    ) async {
      final repository = _ControlledBalancesRepository();
      await tester.pumpWidget(buildScreen(repository: repository));

      expect(find.byKey(const Key('balances_loading')), findsOneWidget);

      repository.complete();
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('balance_summary_card')), findsOneWidget);
    });
  });
}

class _ControlledBalancesRepository implements BalancesRepository {
  final _summaryCompleter = Completer<BalanceSummary>();
  final _peopleCompleter = Completer<List<PersonBalance>>();

  @override
  Future<BalanceSummary> getSummary() => _summaryCompleter.future;

  @override
  Future<List<PersonBalance>> listPeople() => _peopleCompleter.future;

  void complete() {
    _summaryCompleter.complete(
      const BalanceSummary(owedToMeCents: 1000, iOweCents: 0),
    );
    _peopleCompleter.complete(const [
      PersonBalance(
        personKey: 'user:ana',
        displayName: 'Ana',
        status: PersonBalanceStatus.pay,
        netCents: 1000,
      ),
    ]);
  }
}
