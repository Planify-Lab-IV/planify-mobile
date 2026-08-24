import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/auth/presentation/screens/login_screen.dart';
import 'package:planify/features/home/presentation/screens/organizer_home_screen.dart';
import 'package:planify/l10n/app_localizations.dart';
import 'package:planify/main.dart';

Widget _buildTestApp({
  FakeAuthRepository? fakeAuthRepo,
  FakeSecureStorage? fakeStorage,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        fakeAuthRepo ?? FakeAuthRepository(delay: Duration.zero),
      ),
      secureStorageProvider.overrideWithValue(
        fakeStorage ?? FakeSecureStorage(),
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
      home: const LoginScreen(),
    ),
  );
}

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('renderiza campos y botón de inicio de sesión correctamente', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Acceso de Organizador'), findsOneWidget);
      expect(find.byKey(const Key('identifier_input')), findsOneWidget);
      expect(find.byKey(const Key('password_input')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    });

    testWidgets('muestra errores de validación si los campos están vacíos', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Por favor ingresa tu correo o usuario'), findsOneWidget);
      expect(find.text('Por favor ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('muestra error si la contraseña tiene menos de 6 caracteres', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('identifier_input')),
        'organizador@planify.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_input')),
        '123',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('La contraseña debe tener al menos 6 caracteres'), findsOneWidget);
    });

    testWidgets('muestra banner de error ante credenciales inválidas respetando i18n', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('identifier_input')),
        'usuario@desconocido.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_input')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Credenciales inválidas. Verifica tu correo y contraseña.'), findsOneWidget);
    });

    testWidgets('flujo completo: login exitoso con navegación a OrganizerHomeScreen y logout', (tester) async {
      final fakeRepo = FakeAuthRepository(delay: Duration.zero);
      final fakeStorage = FakeSecureStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            secureStorageProvider.overrideWithValue(fakeStorage),
            localeNotifierProvider.overrideWith(
              (ref) => LocaleNotifier()..setLocale(const Locale('es')),
            ),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Estamos en LoginScreen en español
      expect(find.text('Acceso de Organizador'), findsOneWidget);

      // Ingresamos datos de organizador
      await tester.enterText(
        find.byKey(const Key('identifier_input')),
        'organizador@planify.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_input')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      // Navegó a OrganizerHomeScreen
      expect(find.byType(OrganizerHomeScreen), findsOneWidget);
      expect(find.text('¡Bienvenido, Organizador Planify!'), findsOneWidget);

      // Aseguramos visibilidad y presionamos el botón de logout
      await tester.ensureVisible(find.byKey(const Key('logout_button')));
      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();

      // Vuelve a LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Acceso de Organizador'), findsOneWidget);
    });
  });
}
