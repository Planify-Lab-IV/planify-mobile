import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/auth/presentation/widgets/anonymous_login_dialog.dart';
import 'package:planify/l10n/app_localizations.dart';

Widget _buildDialogTestApp({
  String? eventId,
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
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            key: const Key('open_dialog_button'),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AnonymousLoginDialog(eventId: eventId),
            ),
            child: const Text('Abrir Diálogo'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('AnonymousLoginDialog Widget Tests', () {
    testWidgets('renderiza icono, titulo, campos de nombre y PIN, y botones', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDialogTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AnonymousLoginDialog), findsOneWidget);
      expect(find.text('Continuar como invitado'), findsOneWidget);
      expect(find.byKey(const Key('anonymous_name_input')), findsOneWidget);
      expect(find.byKey(const Key('anonymous_pin_input')), findsOneWidget);
      expect(find.byKey(const Key('anonymous_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('anonymous_submit_button')), findsOneWidget);
    });

    testWidgets('muestra badge de evento cuando eventId está presente', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDialogTestApp(eventId: 'EVT-9876'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();

      expect(find.text('ID del Evento: EVT-9876'), findsOneWidget);
      expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);
    });

    testWidgets('muestra errores de validación local con campos vacíos', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDialogTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('anonymous_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Por favor ingresa tu nombre'), findsOneWidget);
      expect(find.text('Por favor ingresa el PIN del evento'), findsOneWidget);
    });

    testWidgets(
      'muestra error si nombre tiene < 2 caracteres o PIN < 4 caracteres',
      (tester) async {
        await tester.pumpWidget(_buildDialogTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('open_dialog_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('anonymous_name_input')),
          'A',
        );
        await tester.enterText(
          find.byKey(const Key('anonymous_pin_input')),
          '12',
        );

        await tester.tap(find.byKey(const Key('anonymous_submit_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('El nombre debe tener al menos 2 caracteres'),
          findsOneWidget,
        );
        expect(
          find.text('El PIN debe tener al menos 4 caracteres'),
          findsOneWidget,
        );
      },
    );

    testWidgets('alterna visibilidad del PIN con el botón de ojo', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDialogTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();

      final pinFieldFinder = find.byKey(const Key('anonymous_pin_input'));
      expect(pinFieldFinder, findsOneWidget);

      final editableText = tester.widget<EditableText>(
        find.descendant(
          of: pinFieldFinder,
          matching: find.byType(EditableText),
        ),
      );
      expect(editableText.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      final editableTextVisible = tester.widget<EditableText>(
        find.descendant(
          of: pinFieldFinder,
          matching: find.byType(EditableText),
        ),
      );
      expect(editableTextVisible.obscureText, isFalse);
    });

    testWidgets('botón Cancelar cierra el diálogo', (tester) async {
      await tester.pumpWidget(_buildDialogTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AnonymousLoginDialog), findsOneWidget);

      await tester.tap(find.byKey(const Key('anonymous_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AnonymousLoginDialog), findsNothing);
    });

    testWidgets('muestra banner de error cuando el PIN es inválido', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDialogTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('anonymous_name_input')),
        'Lucas',
      );
      await tester.enterText(
        find.byKey(const Key('anonymous_pin_input')),
        '9999',
      );

      await tester.tap(find.byKey(const Key('anonymous_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('PIN incorrecto. Verifica el código e intenta nuevamente.'),
        findsOneWidget,
      );
    });
  });
}
