import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/home/presentation/screens/participant_home_screen.dart';
import 'package:planify/features/invitations/data/fake_invitations_repository.dart';
import 'package:planify/features/invitations/presentation/controllers/invitation_providers.dart';
import 'package:planify/main.dart';

import '../unit/deep_link_service_test.dart';

void main() {
  group('Invitation Deep Link Widget Tests', () {
    late FakeAppLinks fakeAppLinks;
    late FakeSecureStorage fakeStorage;
    late FakeAuthRepository fakeAuthRepository;
    late FakeInvitationsRepository fakeInvitationsRepository;

    setUp(() {
      fakeAppLinks = FakeAppLinks();
      fakeStorage = FakeSecureStorage();
      fakeAuthRepository = FakeAuthRepository(
        storage: fakeStorage,
        delay: Duration.zero,
      );
      fakeInvitationsRepository = FakeInvitationsRepository(
        delay: Duration.zero,
      );
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          appLinksProvider.overrideWithValue(fakeAppLinks),
          secureStorageProvider.overrideWithValue(fakeStorage),
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          invitationsRepositoryProvider.overrideWithValue(
            fakeInvitationsRepository,
          ),
          localeNotifierProvider.overrideWith(
            (ref) => LocaleNotifier()..setLocale(const Locale('es')),
          ),
        ],
        child: const MyApp(),
      );
    }

    testWidgets(
      'Deep link con token válido muestra badge de evento y carga eventId en AnonymousLoginDialog',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Emitimos el deep link válido
        fakeAppLinks.emitUri(Uri.parse('planify://invite/token-valid-123'));
        await tester.pumpAndSettle();

        // Verifica que el badge de invitación se muestre con el texto amigable
        expect(find.byKey(const Key('invitation_event_badge')), findsOneWidget);
        expect(find.text('¡Tenés una invitación a un evento!'), findsOneWidget);

        // Ni el ID técnico ni el token confidencial deben aparecer en la UI
        expect(find.textContaining('evt-123'), findsNothing);
        expect(find.textContaining('token-valid-123'), findsNothing);

        // Abre el diálogo de invitado
        final guestButton = find.byKey(const Key('guest_login_button'));
        await tester.ensureVisible(guestButton);
        await tester.tap(guestButton);
        await tester.pumpAndSettle();

        // Verifica que el diálogo tenga el nombre del evento cargado
        expect(find.text('Evento: Cumpleaños de Lucas'), findsOneWidget);

        // Completa el formulario de invitado
        await tester.enterText(
          find.byKey(const Key('anonymous_name_input')),
          'Lucas Invitado',
        );
        await tester.enterText(
          find.byKey(const Key('anonymous_pin_input')),
          '1234',
        );

        // Toca Unirse
        await tester.tap(find.byKey(const Key('anonymous_submit_button')));
        await tester.pumpAndSettle();

        // Debe navegar a ParticipantHomeScreen con la información del evento resuelto
        expect(find.byType(ParticipantHomeScreen), findsOneWidget);
        expect(find.text('¡Bienvenido, Lucas Invitado!'), findsOneWidget);
        expect(find.text('Cumpleaños de Lucas'), findsOneWidget);
      },
    );

    testWidgets(
      'Deep link con token expirado muestra banner de error controlado y permite descartarlo',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Emitimos deep link con token expirado
        fakeAppLinks.emitUri(Uri.parse('planify://invite/token-expired'));
        await tester.pumpAndSettle();

        // Verifica que el banner de error controlado esté visible
        expect(
          find.byKey(const Key('invitation_error_banner')),
          findsOneWidget,
        );
        expect(
          find.text('La invitación ha expirado o ya no está disponible.'),
          findsOneWidget,
        );

        // Toca el botón para descartar el error
        await tester.tap(
          find.byKey(const Key('dismiss_invitation_error_button')),
        );
        await tester.pumpAndSettle();

        // El banner desaparece
        expect(find.byKey(const Key('invitation_error_banner')), findsNothing);
      },
    );

    testWidgets(
      'Deep link con token inexistente muestra banner de error no encontrado',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Emitimos deep link no registrado
        fakeAppLinks.emitUri(
          Uri.parse('planify://invite/token-inexistente-404'),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('invitation_error_banner')),
          findsOneWidget,
        );
        expect(
          find.text(
            'No se encontró el evento correspondiente a la invitación.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Deep link malformado planify://invite muestra error de formato inválido',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Emitimos deep link sin token
        fakeAppLinks.emitUri(Uri.parse('planify://invite'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('invitation_error_banner')),
          findsOneWidget,
        );
        expect(
          find.text('El enlace de invitación no es válido.'),
          findsOneWidget,
        );
      },
    );
  });
}
