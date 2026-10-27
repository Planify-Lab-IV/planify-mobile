import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:planify/l10n/app_localizations.dart';

Widget _buildTestApp({required FakeAuthRepository repository}) {
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
      locale: const Locale('es'),
      home: const ResetPasswordScreen(email: 'organizador@planify.com'),
    ),
  );
}

Future<void> _enterCode(WidgetTester tester, String code) async {
  for (var index = 0; index < code.length; index++) {
    await tester.enterText(
      find.byKey(Key('reset_password_code_digit_$index')),
      code[index],
    );
  }
  await tester.pump();
}

void main() {
  group('ResetPasswordScreen', () {
    testWidgets(
      'muestra el email y habilita el envío al completar el formulario',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(repository: FakeAuthRepository(delay: Duration.zero)),
        );
        await tester.pumpAndSettle();

        final submitButton = find.byKey(
          const Key('reset_password_submit_button'),
        );
        expect(find.text('organizador@planify.com'), findsOneWidget);
        expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);

        await _enterCode(tester, '123456');
        await tester.enterText(
          find.byKey(const Key('reset_password_new_password_input')),
          'contraseña-segura',
        );
        await tester.pump();

        expect(
          tester.widget<ElevatedButton>(submitButton).onPressed,
          isNotNull,
        );
      },
    );

    testWidgets('acepta solo un dígito en cada casillero del código', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(repository: FakeAuthRepository(delay: Duration.zero)),
      );
      await tester.pumpAndSettle();

      final codeField = find.byKey(const Key('reset_password_code_digit_0'));
      await tester.enterText(codeField, 'a1');
      await tester.pump();

      expect(tester.widget<TextFormField>(codeField).controller?.text, '1');
    });

    testWidgets('informa cuando el código no es válido', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(repository: FakeAuthRepository(delay: Duration.zero)),
      );
      await tester.pumpAndSettle();

      await _enterCode(tester, '000000');
      await tester.enterText(
        find.byKey(const Key('reset_password_new_password_input')),
        'contraseña-segura',
      );
      await tester.pump();

      final submitButton = find.byKey(
        const Key('reset_password_submit_button'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('reset_password_error_banner')),
        findsOneWidget,
      );
      expect(
        find.text(
          'El código es inválido o venció. Revisalo e intentá nuevamente.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('confirma el restablecimiento con un código válido', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(repository: FakeAuthRepository(delay: Duration.zero)),
      );
      await tester.pumpAndSettle();

      await _enterCode(tester, '123456');
      await tester.enterText(
        find.byKey(const Key('reset_password_new_password_input')),
        'contraseña-segura',
      );
      await tester.pump();

      final submitButton = find.byKey(
        const Key('reset_password_submit_button'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('reset_password_success_message')),
        findsOneWidget,
      );
      expect(find.text('Volver a iniciar sesión'), findsOneWidget);
    });
  });
}
