import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/invitations/data/fake_invitations_repository.dart';
import 'package:planify/features/invitations/presentation/controllers/invitation_notifier.dart';
import 'package:planify/features/invitations/presentation/controllers/invitation_state.dart';

void main() {
  group('InvitationNotifier', () {
    late FakeInvitationsRepository repository;
    late InvitationNotifier notifier;

    setUp(() {
      repository = FakeInvitationsRepository(delay: Duration.zero);
      notifier = InvitationNotifier(repository);
    });

    test('estado inicial es InvitationInitial', () {
      expect(notifier.state, isA<InvitationInitial>());
    });

    test(
      'ignora links que no son del esquema o host de planify://invite',
      () async {
        await notifier.handleDeepLink(
          Uri.parse('https://planify.app/invite/token-123'),
        );
        expect(notifier.state, isA<InvitationInitial>());

        await notifier.handleDeepLink(Uri.parse('planify://events/123'));
        expect(notifier.state, isA<InvitationInitial>());
      },
    );

    test(
      'link planify://invite sin token cambia estado a InvitationError(invalidFormat)',
      () async {
        await notifier.handleDeepLink(Uri.parse('planify://invite'));
        expect(notifier.state, isA<InvitationError>());
        final errorState = notifier.state as InvitationError;
        expect(errorState.reason, equals(InvitationErrorReason.invalidFormat));
      },
    );

    test(
      'link con token válido cambia estado a InvitationResolved con el eventId correcto',
      () async {
        await notifier.handleDeepLink(
          Uri.parse('planify://invite/token-valid-123'),
        );
        expect(notifier.state, isA<InvitationResolved>());
        final resolved = notifier.state as InvitationResolved;
        expect(resolved.eventId, equals('evt-123'));
      },
    );

    test(
      'link con token expirado cambia estado a InvitationError(expired)',
      () async {
        await notifier.handleDeepLink(
          Uri.parse('planify://invite/token-expired'),
        );
        expect(notifier.state, isA<InvitationError>());
        final errorState = notifier.state as InvitationError;
        expect(errorState.reason, equals(InvitationErrorReason.expired));
      },
    );

    test(
      'link con token inválido cambia estado a InvitationError(invalidFormat)',
      () async {
        await notifier.handleDeepLink(
          Uri.parse('planify://invite/token-invalid'),
        );
        expect(notifier.state, isA<InvitationError>());
        final errorState = notifier.state as InvitationError;
        expect(errorState.reason, equals(InvitationErrorReason.invalidFormat));
      },
    );

    test(
      'link con token inexistente cambia estado a InvitationError(notFound)',
      () async {
        await notifier.handleDeepLink(
          Uri.parse('planify://invite/token-fantasma-404'),
        );
        expect(notifier.state, isA<InvitationError>());
        final errorState = notifier.state as InvitationError;
        expect(errorState.reason, equals(InvitationErrorReason.notFound));
      },
    );

    test(
      'link con error de red cambia estado a InvitationError(network)',
      () async {
        await notifier.handleDeepLink(
          Uri.parse('planify://invite/token-network-error'),
        );
        expect(notifier.state, isA<InvitationError>());
        final errorState = notifier.state as InvitationError;
        expect(errorState.reason, equals(InvitationErrorReason.network));
      },
    );

    test('clearInvitation restablece el estado a InvitationInitial', () async {
      await notifier.handleDeepLink(
        Uri.parse('planify://invite/token-valid-123'),
      );
      expect(notifier.state, isA<InvitationResolved>());

      notifier.clearInvitation();
      expect(notifier.state, isA<InvitationInitial>());
    });
  });
}
