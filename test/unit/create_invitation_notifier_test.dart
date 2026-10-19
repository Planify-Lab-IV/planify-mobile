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
        (notifier.state as CreateInvitationSuccess).invitationUrl,
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
  });
}
