import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/balances/data/fake_balances_repository.dart';
import 'package:planify/features/balances/presentation/controllers/balances_providers.dart';
import 'package:planify/features/home/presentation/screens/registered_home_shell.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  testWidgets('la shell registrada permite alternar entre Inicio y Balances', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          balancesRepositoryProvider.overrideWithValue(
            FakeBalancesRepository(delay: Duration.zero),
          ),
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
          home: const RegisteredHomeShell(
            home: Scaffold(body: Center(child: Text('Inicio de prueba'))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('registered_navigation_bar')), findsOneWidget);
    expect(find.text('Inicio de prueba'), findsOneWidget);
    expect(find.text('Balances'), findsOneWidget);

    await tester.tap(find.byKey(const Key('registered_navigation_balances')));
    await tester.pumpAndSettle();

    expect(find.text('Saldos por persona'), findsOneWidget);
    expect(find.byKey(const Key('balance_summary_card')), findsOneWidget);
  });
}
