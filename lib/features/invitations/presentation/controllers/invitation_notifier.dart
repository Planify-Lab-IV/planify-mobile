import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/invitation_exceptions.dart';
import '../../domain/invitation_link_parser.dart';
import '../../domain/invitations_repository.dart';
import 'invitation_state.dart';

class InvitationNotifier extends StateNotifier<InvitationState> {
  final InvitationsRepository _repository;

  InvitationNotifier(this._repository) : super(const InvitationInitial());

  /// Si el URI no pertenece al esquema y host de invitaciones de Planify,
  /// se ignora sin alterar el estado actual.
  /// Si pertenece pero no incluye un token válido, establece [InvitationErrorReason.invalidFormat].
  Future<void> handleDeepLink(Uri uri) async {
    if (!InvitationLinkParser.isInvitationLink(uri)) {
      return;
    }

    final token = InvitationLinkParser.parseToken(uri);
    if (token == null) {
      state = const InvitationError(InvitationErrorReason.invalidFormat);
      return;
    }

    state = const InvitationLoading();

    try {
      final eventId = await _repository.resolveInvitationToken(token);
      state = InvitationResolved(eventId);
    } on InvalidInvitationException {
      state = const InvitationError(InvitationErrorReason.invalidFormat);
    } on InvitationNotFoundException {
      state = const InvitationError(InvitationErrorReason.notFound);
    } on InvitationExpiredException {
      state = const InvitationError(InvitationErrorReason.expired);
    } on NetworkInvitationException {
      state = const InvitationError(InvitationErrorReason.network);
    } catch (_) {
      state = const InvitationError(InvitationErrorReason.unknown);
    }
  }

  void clearInvitation() {
    state = const InvitationInitial();
  }
}
