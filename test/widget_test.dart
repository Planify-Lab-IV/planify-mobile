// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planify/main.dart';

void main() {
  testWidgets('Smoke test de PlaceholderScreen', (WidgetTester tester) async {
    // 1. Levantamos la app envuelta en Riverpod (exactamente igual que en tu main.dart)
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // 2. Le decimos al tester que espere a que se carguen los idiomas y colores
    await tester.pumpAndSettle();

    // 3. LA PRUEBA: Verificamos que se haya cargado tu pantalla buscando un texto
    expect(find.text('Hola, esta es una prueba de i18n'), findsOneWidget);
  });
}
