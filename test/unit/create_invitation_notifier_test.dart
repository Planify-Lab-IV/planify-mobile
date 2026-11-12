import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/invitations/data/fake_invitations_repository.dart';
import 'package:planify/features/invitations/data/invitation_exceptions.dart';
import 'package:planify/features/invitations/presentation/controllers/create_invitation_notifier.dart';
import 'package:planify/features/invitations/presentation/controllers/create_invitation_state.dart';

void main() {
  group('CreateInvitationNotifier', () {
    test('crea el link y lo reutiliza sin una segunda petición', () async {
      final repository = FakeInvitationsRepository(delay: Duration.zero);
      final notifier = CreateInvitationNotifier(
        repository: repository,
        eventId: 'evt-123',
      );

      await notifier.createInvitation();

      expect(notifier.state, isA<CreateInvitationSuccess>());
      expect(
        (notifier.state as CreateInvitationSuccess).shareUrl,
        'planify://invite/token-valid-123',
      );
      expect(repository.createInvitationCalls, 1);

      await notifier.createInvitation();
      expect(repository.createInvitationCalls, 1);
    });

    test('expone el error recibido del repositorio', () async {
      final notifier = CreateInvitationNotifier(
        repository: FakeInvitationsRepository(
          delay: Duration.zero,
          createInvitationException:
              const InvitationEventUnavailableException(),
        ),
        eventId: 'evt-123',
      );

      await notifier.createInvitation();

      expect(notifier.state, isA<CreateInvitationError>());
      expect(
        (notifier.state as CreateInvitationError).exception,
        isA<InvitationEventUnavailableException>(),
      );
    });

    test('construye un enlace HTTPS al crear una invitación en Web', () async {
      final notifier = CreateInvitationNotifier(
        repository: FakeInvitationsRepository(delay: Duration.zero),
        eventId: 'evt-123',
        isWeb: true,
        webBaseUriProvider: () => Uri.parse('https://planify-austral.web.app'),
      );

      await notifier.createInvitation();

      expect(
        notifier.state,
        const CreateInvitationSuccess(
          'https://planify-austral.web.app/?invite=token-valid-123',
        ),
      );
    });

    test(
      'mapea errores al construir el enlace Web a un error conocido',
      () async {
        final notifier = CreateInvitationNotifier(
          repository: FakeInvitationsRepository(delay: Duration.zero),
          eventId: 'evt-123',
          isWeb: true,
          webBaseUriProvider: () => Uri.parse('http://localhost:8080'),
        );

        await notifier.createInvitation();

        expect(notifier.state, isA<CreateInvitationError>());
        expect(
          (notifier.state as CreateInvitationError).exception,
          isA<UnknownInvitationException>(),
        );
      },
    );
  });
}
