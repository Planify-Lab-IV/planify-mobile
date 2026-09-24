import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/data/http_auth_repository.dart';
import 'package:planify/features/auth/domain/auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/auth/presentation/widgets/anonymous_login_dialog.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/detail/controllers/events_providers.dart';
import 'package:planify/l10n/app_localizations.dart';

Widget _buildDialogTestApp({
  String? eventId,
  AuthRepository? authRepository,
  FakeSecureStorage? fakeStorage,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        authRepository ?? FakeAuthRepository(delay: Duration.zero),
      ),
      secureStorageProvider.overrideWithValue(
        fakeStorage ?? FakeSecureStorage(),
      ),
      eventsRepositoryProvider.overrideWithValue(
        FakeEventsRepository(delay: Duration.zero),
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

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (var index = 0; index < pin.length; index++) {
    await tester.enterText(
      find.byKey(Key('anonymous_pin_digit_$index')),
      pin[index],
    );
  }
}

Future<void> _tapDialogButton(WidgetTester tester, Key key) async {
  final button = find.byKey(key);
  await tester.scrollUntilVisible(
    button,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(button);
}

void main() {
  group('AnonymousLoginDialog Widget Tests', () {
    testWidgets('renderiza subtítulo, casilleros PIN y aviso de recuperación', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDialogTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AnonymousLoginDialog), findsOneWidget);
      expect(find.text('Continuar como invitado'), findsOneWidget);
      expect(find.byKey(const Key('anonymous_name_input')), findsOneWidget);
      expect(
        find.text(
          'Elegí un PIN de 4 dígitos para identificarte en este evento.',
        ),
        findsOneWidget,
      );
      for (var index = 0; index < 4; index++) {
        final pinField = tester.widget<TextField>(
          find.byKey(Key('anonymous_pin_digit_$index')),
        );
        expect(pinField.keyboardType, TextInputType.number);
      }
      final firstPinFieldWidth = tester
          .getSize(find.byKey(const Key('anonymous_pin_digit_0')))
          .width;
      for (var index = 1; index < 4; index++) {
        expect(
          tester.getSize(find.byKey(Key('anonymous_pin_digit_$index'))).width,
          closeTo(firstPinFieldWidth, 0.01),
        );
      }
      expect(find.byKey(const Key('anonymous_pin_info_card')), findsOneWidget);
      expect(
        find.text('¿Ya ingresaste a este evento con este nombre?'),
        findsOneWidget,
      );
      expect(
        find.text('Usá el mismo PIN para recuperar tu acceso.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('anonymous_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('anonymous_submit_button')), findsOneWidget);
    });

    testWidgets('muestra errores de validación local con campos vacíos', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDialogTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();

      await _tapDialogButton(tester, const Key('anonymous_submit_button'));
      await tester.pumpAndSettle();

      expect(find.text('Por favor ingresa tu nombre'), findsOneWidget);
      expect(find.text('Por favor ingresá tu PIN de acceso'), findsOneWidget);
    });

    testWidgets('muestra error cuando el nombre supera los 80 caracteres', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDialogTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('anonymous_name_input')),
        'a' * 81,
      );
      await _enterPin(tester, '1234');

      await _tapDialogButton(tester, const Key('anonymous_submit_button'));
      await tester.pumpAndSettle();

      expect(
        find.text('El nombre no puede superar los 80 caracteres'),
        findsOneWidget,
      );
    });

    testWidgets(
      'acepta nombres de un carácter y rechaza PIN que no tenga cuatro dígitos',
      (tester) async {
        await tester.pumpWidget(_buildDialogTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('open_dialog_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('anonymous_name_input')),
          'A',
        );
        await _enterPin(tester, '12');

        await _tapDialogButton(tester, const Key('anonymous_submit_button'));
        await tester.pumpAndSettle();

        expect(
          find.text('El PIN debe tener exactamente 4 dígitos'),
          findsOneWidget,
        );
      },
    );

    testWidgets('avanza al siguiente casillero al ingresar cada dígito', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDialogTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('anonymous_pin_digit_0')),
        '1',
      );
      await tester.pump();

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('anonymous_pin_digit_1')))
            .focusNode
            ?.hasFocus,
        isTrue,
      );
    });

    testWidgets('botón Cancelar cierra el diálogo', (tester) async {
      await tester.pumpWidget(_buildDialogTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AnonymousLoginDialog), findsOneWidget);

      await _tapDialogButton(tester, const Key('anonymous_cancel_button'));
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
      await _enterPin(tester, '9999');

      await _tapDialogButton(tester, const Key('anonymous_submit_button'));
      await tester.pumpAndSettle();

      expect(
        find.text('PIN incorrecto. Verifica el código e intenta nuevamente.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra un error específico cuando el evento no existe', (
      tester,
    ) async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 404,
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        _buildDialogTestApp(
          eventId: 'event-missing',
          authRepository: HttpAuthRepository(
            dio: dio,
            storage: FakeSecureStorage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open_dialog_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('anonymous_name_input')),
        'Gil',
      );
      await _enterPin(tester, '1234');

      await _tapDialogButton(tester, const Key('anonymous_submit_button'));
      await tester.pumpAndSettle();

      expect(
        find.text('El evento ya no existe o no está disponible.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'muestra el mensaje de error cuando el evento no está disponible (409)',
      (tester) async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 409,
                ),
              ),
            ),
          ),
        );

        await tester.pumpWidget(
          _buildDialogTestApp(
            eventId: 'event-unavailable',
            authRepository: HttpAuthRepository(
              dio: dio,
              storage: FakeSecureStorage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('open_dialog_button')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('anonymous_name_input')),
          'Gil',
        );
        await _enterPin(tester, '1234');

        await _tapDialogButton(tester, const Key('anonymous_submit_button'));
        await tester.pumpAndSettle();

        expect(find.text('El evento no está disponible.'), findsOneWidget);
      },
    );

    testWidgets(
      'envía el nombre normalizado y el PIN de los casilleros al backend',
      (tester) async {
        RequestOptions? capturedRequest;
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              capturedRequest = options;
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'participant': {
                      'id': 'part-1',
                      'eventId': 'event-trim-test',
                      'username': 'Lucas',
                      'isAnonymous': true,
                    },
                    'token': 'fake-token',
                  },
                ),
              );
            },
          ),
        );

        await tester.pumpWidget(
          _buildDialogTestApp(
            eventId: 'event-trim-test',
            authRepository: HttpAuthRepository(
              dio: dio,
              storage: FakeSecureStorage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('open_dialog_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('anonymous_name_input')),
          '  Lucas  ',
        );
        await _enterPin(tester, '1234');

        await _tapDialogButton(tester, const Key('anonymous_submit_button'));
        await tester.pumpAndSettle();

        expect(capturedRequest?.data, {'name': 'Lucas', 'pin': '1234'});
      },
    );
  });
}
