import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:planify/l10n/app_localizations.dart';

Widget _buildTestApp({
  required FakeAuthRepository repository,
  Locale locale = const Locale('es'),
}) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
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
      home: const ForgotPasswordScreen(),
    ),
  );
}

void main() {
  group('ForgotPasswordScreen', () {
    testWidgets('habilita el envío solo con un email válido', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(repository: FakeAuthRepository(delay: Duration.zero)),
      );
      await tester.pumpAndSettle();

      final submitButton = find.byKey(
        const Key('forgot_password_submit_button'),
      );
      expect(find.text('Recuperar contraseña'), findsOneWidget);
      expect(
        find.byKey(const Key('forgot_password_success_message')),
        findsNothing,
      );
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('forgot_password_email_input')),
        'lucas@planify.com',
      );
      await tester.pump();

      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);
    });

    testWidgets('muestra el mensaje genérico después de solicitar el código', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(repository: FakeAuthRepository(delay: Duration.zero)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('forgot_password_email_input')),
        'missing@planify.com',
      );
      await tester.pump();
      final submitButton = find.byKey(
        const Key('forgot_password_submit_button'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('forgot_password_success_message')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Si ese email está registrado,\nvas a recibir un código de 6 dígitos.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('forgot_password_have_code_button')),
        findsOneWidget,
      );
      expect(find.text('Reenviar'), findsOneWidget);
      final haveCodeButton = find.byKey(
        const Key('forgot_password_have_code_button'),
      );
      final successMessage = find.byKey(
        const Key('forgot_password_success_message'),
      );
      final emailInput = find.byKey(const Key('forgot_password_email_input'));
      await tester.ensureVisible(haveCodeButton);
      expect(
        tester.getRect(successMessage).bottom,
        lessThan(tester.getRect(emailInput).top),
      );
      expect(
        tester.getRect(haveCodeButton).top,
        greaterThan(tester.getRect(submitButton).bottom),
      );

      await tester.tap(haveCodeButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('reset_password_email_sent')),
        findsOneWidget,
      );
      expect(find.text('Código enviado a missing@planify.com'), findsOneWidget);
    });

    testWidgets('muestra un error de red y conserva el email escrito', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(repository: FakeAuthRepository(delay: Duration.zero)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('forgot_password_email_input')),
        'network.error@planify.com',
      );
      await tester.pump();
      final submitButton = find.byKey(
        const Key('forgot_password_submit_button'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('forgot_password_error_banner')),
        findsOneWidget,
      );
      expect(
        find.text(
          'No pudimos enviar el código por un problema de conexión. Intentá nuevamente.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('forgot_password_success_message')),
        findsNothing,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('forgot_password_email_input')),
            )
            .controller
            ?.text,
        'network.error@planify.com',
      );
    });

    testWidgets('oculta el acceso al código al cambiar el email solicitado', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(repository: FakeAuthRepository(delay: Duration.zero)),
      );
      await tester.pumpAndSettle();

      final emailInput = find.byKey(const Key('forgot_password_email_input'));
      final submitButton = find.byKey(
        const Key('forgot_password_submit_button'),
      );
      final haveCodeButton = find.byKey(
        const Key('forgot_password_have_code_button'),
      );

      await tester.enterText(emailInput, 'primero@planify.com');
      await tester.pump();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(haveCodeButton, findsOneWidget);
      expect(find.text('Reenviar'), findsOneWidget);

      await tester.enterText(emailInput, 'ultimo@planify.com');
      await tester.pump();

      expect(haveCodeButton, findsNothing);
      expect(find.text('Enviar'), findsOneWidget);
      expect(
        find.byKey(const Key('forgot_password_success_message')),
        findsNothing,
      );

      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      await tester.ensureVisible(haveCodeButton);
      await tester.tap(haveCodeButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('reset_password_email_sent')),
        findsOneWidget,
      );
      expect(find.text('Código enviado a ultimo@planify.com'), findsOneWidget);
    });

    testWidgets('muestra los textos de recuperación en inglés', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          repository: FakeAuthRepository(delay: Duration.zero),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset password'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
      expect(
        find.byKey(const Key('forgot_password_success_message')),
        findsNothing,
      );
    });
  });
}
