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
  /// URL ya preparada para mostrar y compartir en la plataforma actual.
  final String shareUrl;

  const CreateInvitationSuccess(this.shareUrl);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateInvitationSuccess && other.shareUrl == shareUrl;

  @override
  int get hashCode => shareUrl.hashCode;
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
