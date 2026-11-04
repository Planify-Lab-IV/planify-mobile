import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/invitation_exceptions.dart';
import '../../domain/invitation_link_parser.dart';
import '../../domain/invitations_repository.dart';
import 'create_invitation_state.dart';

class CreateInvitationNotifier extends StateNotifier<CreateInvitationState> {
  final InvitationsRepository _repository;
  final String _eventId;

  CreateInvitationNotifier({
    required InvitationsRepository repository,
    required String eventId,
  }) : this._(repository, eventId);

  CreateInvitationNotifier._(this._repository, this._eventId)
    : super(const CreateInvitationInitial());

  Future<void> createInvitation() async {
    if (state is CreateInvitationLoading || state is CreateInvitationSuccess) {
      return;
    }

    state = const CreateInvitationLoading();
    try {
      final backendInvitationUrl = await _repository.createInvitation(_eventId);
      final shareUrl = InvitationLinkParser.buildShareUrl(
        invitationUrl: backendInvitationUrl,
        isWeb: kIsWeb,
        webBaseUri: kIsWeb ? Uri.base : null,
      );
      if (!mounted) return;
      state = CreateInvitationSuccess(shareUrl);
    } on InvitationException catch (error) {
      if (!mounted) return;
      state = CreateInvitationError(error);
    } catch (_) {
      if (!mounted) return;
      state = const CreateInvitationError(UnknownInvitationException());
    }
  }
}
