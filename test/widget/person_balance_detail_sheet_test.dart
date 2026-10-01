import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_colors.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/balances/data/fake_balances_repository.dart';
import 'package:planify/features/balances/domain/balances_repository.dart';
import 'package:planify/features/balances/presentation/controllers/balances_providers.dart';
import 'package:planify/features/balances/presentation/widgets/person_balance_detail_sheet.dart';
import 'package:planify/features/events/detail/screens/event_detail_screen.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  Widget buildApp({
    required BalancesRepository repository,
    required String personKey,
    Locale locale = const Locale('es'),
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
        locale: locale,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () =>
                    PersonBalanceDetailSheet.show(context, personKey),
                child: const Text('Abrir detalle'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(
    WidgetTester tester, {
    required BalancesRepository repository,
    required String personKey,
    Locale locale = const Locale('es'),
  }) async {
    await tester.pumpWidget(
      buildApp(repository: repository, personKey: personKey, locale: locale),
    );
    await tester.tap(find.text('Abrir detalle'));
    await tester.pumpAndSettle();
  }

  Text netAmount(WidgetTester tester) {
    return tester.widget<Text>(
      find.byKey(const Key('person_balance_detail_net_amount')),
    );
  }

  group('PersonBalanceDetailSheet', () {
    testWidgets('muestra el encabezado de una deuda con texto y color', (
      tester,
    ) async {
      await openSheet(
        tester,
        repository: FakeBalancesRepository(delay: Duration.zero),
        personKey: 'user:ana',
      );

      expect(find.text(r'Le debés $ 243,00 a Ana'), findsOneWidget);
      expect(netAmount(tester).style?.color, AppColors.danger);
    });

    testWidgets('muestra el encabezado de un saldo a favor con texto y color', (
      tester,
    ) async {
      await openSheet(
        tester,
        repository: FakeBalancesRepository(delay: Duration.zero),
        personKey: 'participant:martin',
      );

      expect(find.text(r'Martín te debe $ 825,00'), findsOneWidget);
      expect(netAmount(tester).style?.color, AppColors.success);
    });

    testWidgets('muestra el encabezado saldado', (tester) async {
      await openSheet(
        tester,
        repository: FakeBalancesRepository(delay: Duration.zero),
        personKey: 'user:sol',
      );

      expect(find.text('Están a mano'), findsOneWidget);
      expect(find.text(r'$ 0,00'), findsOneWidget);
    });

    testWidgets('muestra evento, monto y sentido de cada línea', (
      tester,
    ) async {
      await openSheet(
        tester,
        repository: FakeBalancesRepository(delay: Duration.zero),
        personKey: 'user:ana',
      );

      expect(find.text('Asado'), findsOneWidget);
      expect(find.text(r'$ 500,00'), findsOneWidget);
      expect(find.text('Le debés a Ana'), findsOneWidget);
      expect(find.text('Cine'), findsOneWidget);
      expect(find.text(r'$ 257,00'), findsOneWidget);
      expect(find.text('Ana te debe'), findsOneWidget);
    });

    testWidgets('muestra todos los textos de detalle en inglés', (tester) async {
      await openSheet(
        tester,
        repository: FakeBalancesRepository(delay: Duration.zero),
        personKey: 'user:ana',
        locale: const Locale('en'),
      );

      expect(find.text(r'You owe $ 243.00 to Ana'), findsOneWidget);
      expect(find.text('Breakdown by event'), findsOneWidget);
      expect(find.text('You owe Ana'), findsOneWidget);
      expect(find.text('Ana owes you'), findsOneWidget);
      expect(find.text('Desglose por evento'), findsNothing);
      expect(find.text('Le debés a Ana'), findsNothing);
    });

    testWidgets('usa fondo cian y una tarjeta contrastada para cada evento', (
      tester,
    ) async {
      await openSheet(
        tester,
        repository: FakeBalancesRepository(delay: Duration.zero),
        personKey: 'user:ana',
      );

      final background = tester.widget<ColoredBox>(
        find.byKey(const Key('person_balance_detail_background')),
      );
      final eventCard = tester.widget<Card>(
        find.ancestor(
          of: find.byKey(const Key('person_balance_detail_line_event:asado')),
          matching: find.byType(Card),
        ),
      );

      expect(background.color, AppColors.background);
      expect(eventCard.color, AppColors.surface);
      expect(eventCard.elevation, 2);
    });

    testWidgets('cierra la hoja y abre el evento al tocar una línea', (
      tester,
    ) async {
      await openSheet(
        tester,
        repository: FakeBalancesRepository(delay: Duration.zero),
        personKey: 'user:ana',
      );

      await tester.tap(
        find.byKey(const Key('person_balance_detail_line_event:asado')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byKey(const Key('person_balance_detail_sheet')),
        findsNothing,
      );
      expect(find.byType(EventDetailScreen), findsOneWidget);
    });

    testWidgets('muestra el error y permite reintentar en inglés', (tester) async {
      final repository = FakeBalancesRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      );
      await openSheet(
        tester,
        repository: repository,
        personKey: 'user:ana',
        locale: const Locale('en'),
      );

      expect(find.text('Could not load the balance details.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      repository.shouldThrowError = false;

      await tester.tap(
        find.byKey(const Key('person_balance_detail_retry_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('person_balance_detail_sheet')),
        findsOneWidget,
      );
    });
  });
}
