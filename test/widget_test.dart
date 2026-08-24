import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/main.dart';

void main() {
  testWidgets('Smoke test de inicio de la aplicación Planify', (
    WidgetTester tester,
  ) async {
    // 1. Levantamos la app envuelta en Riverpod
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(delay: Duration.zero),
          ),
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          localeNotifierProvider.overrideWith(
            (ref) => LocaleNotifier()..setLocale(const Locale('es')),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // 2. Esperamos a que se carguen los delegados de idiomas y el tema
    await tester.pumpAndSettle();

    // 3. Verificamos que la app inicie en la pantalla de Login de Organizador en español
    expect(find.text('Acceso de Organizador'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
