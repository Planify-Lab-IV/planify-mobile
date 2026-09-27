import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/expenses/presentation/widgets/expense_header_fields.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  Widget buildSubject({
    required ValueChanged<String> onDescriptionChanged,
    required ValueChanged<int?> onTotalAmountChanged,
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
        body: ExpenseHeaderFields(
          onDescriptionChanged: onDescriptionChanged,
          onTotalAmountChanged: onTotalAmountChanged,
        ),
      ),
    );
  }

  testWidgets('emite la descripción y convierte el total a centavos', (
    tester,
  ) async {
    String? description;
    int? totalAmountCents;

    await tester.pumpWidget(
      buildSubject(
        onDescriptionChanged: (value) => description = value,
        onTotalAmountChanged: (value) => totalAmountCents = value,
      ),
    );

    await tester.enterText(
      find.byKey(const Key('expense_description_field')),
      'Cena de fin de año',
    );
    await tester.enterText(
      find.byKey(const Key('expense_total_field')),
      '1.250,50',
    );
    await tester.pump();

    expect(description, 'Cena de fin de año');
    expect(totalAmountCents, 125050);
  });

  testWidgets('informa un total inválido sin inventar centavos', (
    tester,
  ) async {
    int? totalAmountCents = 500;

    await tester.pumpWidget(
      buildSubject(
        onDescriptionChanged: (_) {},
        onTotalAmountChanged: (value) => totalAmountCents = value,
      ),
    );

    await tester.enterText(
      find.byKey(const Key('expense_total_field')),
      'mucho',
    );
    await tester.pump();

    expect(totalAmountCents, isNull);
    expect(find.text('Ingresá un total válido mayor a cero.'), findsOneWidget);
  });
}
