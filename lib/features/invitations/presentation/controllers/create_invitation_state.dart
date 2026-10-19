import '../../data/invitation_exceptions.dart';

sealed class CreateInvitationState {
  const CreateInvitationState();
}

class CreateInvitationInitial extends CreateInvitationState {
  const CreateInvitationInitial();
}

class CreateInvitationLoading extends CreateInvitationState {
  const CreateInvitationLoading();
}

class CreateInvitationSuccess extends CreateInvitationState {
  final String invitationUrl;

  const CreateInvitationSuccess(this.invitationUrl);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateInvitationSuccess && other.invitationUrl == invitationUrl;

  @override
  int get hashCode => invitationUrl.hashCode;
}

class CreateInvitationError extends CreateInvitationState {
  final InvitationException exception;

  const CreateInvitationError(this.exception);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateInvitationError && other.exception == exception;

  @override
  int get hashCode => exception.hashCode;
}
