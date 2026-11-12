import '../domain/invitations_repository.dart';
import 'invitation_exceptions.dart';

class FakeInvitationsRepository implements InvitationsRepository {
  final Duration delay;
  final InvitationException? createInvitationException;
  final String invitationUrl;
  int createInvitationCalls = 0;

  FakeInvitationsRepository({
    this.delay = const Duration(milliseconds: 400),
    this.createInvitationException,
    this.invitationUrl = 'planify://invite/token-valid-123',
  });

  @override
  Future<String> createInvitation(String eventId) async {
    createInvitationCalls++;
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    if (createInvitationException != null) {
      throw createInvitationException!;
    }
    return invitationUrl;
  }

  @override
  Future<String> resolveInvitationToken(String token) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    final trimmedToken = token.trim();

    if (trimmedToken.isEmpty) {
      throw const InvalidInvitationException();
    }

    if (trimmedToken == 'token-network-error' ||
        trimmedToken == 'network-error') {
      throw const NetworkInvitationException();
    }

    if (trimmedToken == 'token-invalid' || trimmedToken == 'invalid-token') {
      throw const InvalidInvitationException();
    }

    if (trimmedToken == 'token-expired' || trimmedToken == 'expired-token') {
      throw const InvitationExpiredException();
    }

    if (trimmedToken == 'token-unknown-error' ||
        trimmedToken == 'unknown-error') {
      throw const UnknownInvitationException();
    }

    if (trimmedToken == 'token-valid-123' || trimmedToken == 'valid-token') {
      return 'evt-123';
    }

    if (trimmedToken == 'token-cumple-lucas') {
      return 'evt-cumple-lucas';
    }

    if (trimmedToken.startsWith('valid-')) {
      final suffix = trimmedToken.replaceFirst('valid-', '');
      return 'evt-$suffix';
    }

    // Por defecto, cualquier token no registrado se considera no encontrado
    throw const InvitationNotFoundException();
  }
}
