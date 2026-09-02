import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/core/widgets/planify_logo.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/auth/presentation/screens/login_screen.dart';
import 'package:planify/features/home/presentation/screens/organizer_home_screen.dart';
import 'package:planify/l10n/app_localizations.dart';
import 'package:planify/main.dart';

import 'package:planify/features/auth/presentation/widgets/anonymous_login_dialog.dart';
import 'package:planify/features/home/presentation/screens/participant_home_screen.dart';

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
    testWidgets('renderiza logo, titulo, eslogan, campos y botones', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(PlanifyLogo), findsOneWidget);
      expect(find.text('Planify'), findsOneWidget);
      expect(find.text('Organizá tus planes, sin vueltas'), findsOneWidget);
      expect(find.byKey(const Key('identifier_input')), findsOneWidget);
      expect(find.byKey(const Key('password_input')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('guest_login_button')), findsOneWidget);
    });

    testWidgets('muestra errores de validación si los campos están vacíos', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Por favor ingresa tu correo o usuario'),
        findsOneWidget,
      );
      expect(find.text('Por favor ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('muestra error si la contraseña tiene menos de 6 caracteres', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('identifier_input')),
        'lucas@gmail.com',
      );
      await tester.enterText(find.byKey(const Key('password_input')), '123');

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('La contraseña debe tener al menos 6 caracteres'),
        findsOneWidget,
      );
    });

    testWidgets('ingreso como invitado abre AnonymousLoginDialog', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guest_login_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AnonymousLoginDialog), findsOneWidget);
    });

    testWidgets(
      'flujo completo: login como invitado navega a ParticipantHomeScreen y logout',
      (tester) async {
        final fakeStorage = FakeSecureStorage();
        final fakeRepo = FakeAuthRepository(
          storage: fakeStorage,
          delay: Duration.zero,
        );

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

        expect(find.text('Planify'), findsOneWidget);

        await tester.tap(find.byKey(const Key('guest_login_button')));
        await tester.pumpAndSettle();

        expect(find.byType(AnonymousLoginDialog), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('anonymous_name_input')),
          'Lucas Invitado',
        );
        await tester.enterText(
          find.byKey(const Key('anonymous_pin_input')),
          '1234',
        );

        await tester.tap(find.byKey(const Key('anonymous_submit_button')));
        await tester.pumpAndSettle();

        expect(find.byType(ParticipantHomeScreen), findsOneWidget);
        expect(find.text('¡Bienvenido, Lucas Invitado!'), findsOneWidget);
        expect(find.text('Evento: '), findsOneWidget);
        expect(find.text('Evento Demo'), findsOneWidget);

        await tester.ensureVisible(find.byKey(const Key('logout_button')));
        await tester.tap(find.byKey(const Key('logout_button')));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    testWidgets(
      'flujo completo: login como organizador navega a OrganizerHomeScreen y logout',
      (tester) async {
        final fakeStorage = FakeSecureStorage();
        final fakeRepo = FakeAuthRepository(
          storage: fakeStorage,
          delay: Duration.zero,
        );

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

        expect(find.text('Planify'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('identifier_input')),
          'lucas@gmail.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_input')),
          'password123',
        );

        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pumpAndSettle();

        expect(find.byType(OrganizerHomeScreen), findsOneWidget);
        expect(find.text('¡Bienvenido, lucas!'), findsOneWidget);

        await tester.ensureVisible(find.byKey(const Key('logout_button')));
        await tester.tap(find.byKey(const Key('logout_button')));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  });
}
