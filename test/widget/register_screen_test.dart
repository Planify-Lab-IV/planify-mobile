import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/auth/presentation/screens/register_screen.dart';
import 'package:planify/l10n/app_localizations.dart';

Widget _buildTestApp({
  required FakeAuthRepository repository,
  required FakeSecureStorage storage,
  Widget? home,
  Locale locale = const Locale('es'),
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      secureStorageProvider.overrideWithValue(storage),
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
      locale: locale,
      home: home ?? const RegisterScreen(),
    ),
  );
}

Future<void> _completeValidRegistration(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('registration_name_input')),
    'Lucía Planes',
  );
  await tester.enterText(
    find.byKey(const Key('registration_username_input')),
    'lucia_planes',
  );
  await tester.enterText(
    find.byKey(const Key('registration_email_input')),
    'lucia@planify.com',
  );
  await tester.enterText(
    find.byKey(const Key('registration_password_input')),
    'password123',
  );
  await tester.pump();
  await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
  await tester.pumpAndSettle();
}

void main() {
  group('RegisterScreen', () {
    testWidgets('muestra el formulario y habilita el envío con datos válidos', (
      tester,
    ) async {
      final storage = FakeSecureStorage();
      final repository = FakeAuthRepository(
        storage: storage,
        delay: Duration.zero,
      );

      await tester.pumpWidget(
        _buildTestApp(repository: repository, storage: storage),
      );
      await tester.pumpAndSettle();

      final submitButton = find.byKey(const Key('register_submit_button'));
      expect(find.text('Crear cuenta'), findsOneWidget);
      expect(find.byKey(const Key('registration_name_input')), findsOneWidget);
      expect(
        find.byKey(const Key('registration_username_input')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('registration_email_input')), findsOneWidget);
      expect(
        find.byKey(const Key('registration_password_input')),
        findsOneWidget,
      );
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);

      await _completeValidRegistration(tester);

      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);
    });

    testWidgets('muestra los textos de registro en inglés', (tester) async {
      final storage = FakeSecureStorage();
      final repository = FakeAuthRepository(
        storage: storage,
        delay: Duration.zero,
      );

      await tester.pumpWidget(
        _buildTestApp(
          repository: repository,
          storage: storage,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create account'), findsNWidgets(2));
      expect(find.text('Use lowercase letters, numbers and _'), findsOneWidget);
    });

    testWidgets('muestra conflicto genérico sin marcar ningún campo', (
      tester,
    ) async {
      final storage = FakeSecureStorage();
      final repository = FakeAuthRepository(
        storage: storage,
        delay: Duration.zero,
        usedUsernames: const ['lucia_planes'],
      );

      await tester.pumpWidget(
        _buildTestApp(repository: repository, storage: storage),
      );
      await tester.pumpAndSettle();
      await _completeValidRegistration(tester);

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_error_banner')), findsOneWidget);
      expect(
        find.text(
          'No pudimos crear la cuenta con esos datos. Si ya tenés una cuenta, iniciá sesión.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('El nombre debe tener entre 1 y 80 caracteres'),
        findsNothing,
      );
      expect(
        find.text(
          'El usuario debe tener entre 3 y 30 caracteres y usar solo minúsculas, números o _',
        ),
        findsNothing,
      );
      expect(find.text('Ingresá un correo electrónico válido'), findsNothing);
      expect(
        find.text('La contraseña debe tener entre 8 y 72 caracteres'),
        findsNothing,
      );
    });

    testWidgets('cierra la ruta de registro después de registrarse', (
      tester,
    ) async {
      final storage = FakeSecureStorage();
      final repository = FakeAuthRepository(
        storage: storage,
        delay: Duration.zero,
      );

      await tester.pumpWidget(
        _buildTestApp(
          repository: repository,
          storage: storage,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('open_register_screen_button'),
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('Abrir registro'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_register_screen_button')));
      await tester.pumpAndSettle();
      await _completeValidRegistration(tester);

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsNothing);
      expect(
        find.byKey(const Key('open_register_screen_button')),
        findsOneWidget,
      );
    });
  });
}
