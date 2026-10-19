import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/invitation_exceptions.dart';
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
      final invitationUrl = await _repository.createInvitation(_eventId);
      if (!mounted) return;
      state = CreateInvitationSuccess(invitationUrl);
    } on InvitationException catch (error) {
      if (!mounted) return;
      state = CreateInvitationError(error);
    } catch (_) {
      if (!mounted) return;
      state = const CreateInvitationError(UnknownInvitationException());
    }
  }
}
