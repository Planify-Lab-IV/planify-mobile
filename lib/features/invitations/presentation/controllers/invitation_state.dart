sealed class InvitationState {
  const InvitationState();
}

/// Estado inicial, cuando no hay ningún link de invitación activo.
class InvitationInitial extends InvitationState {
  const InvitationInitial();
}

/// Estado mientras se parsea y resuelve el token con el repositorio.
class InvitationLoading extends InvitationState {
  const InvitationLoading();
}

/// Estado exitoso: el token fue resuelto y se obtuvo el [eventId].
class InvitationResolved extends InvitationState {
  final String eventId;

  const InvitationResolved(this.eventId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvitationResolved &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId;

  @override
  int get hashCode => eventId.hashCode;
}

enum InvitationErrorReason {
  invalidFormat,
  notFound,
  expired,
  network,
  unknown,
}

/// Estado de error cuando la invitación no pudo ser resuelta.
class InvitationError extends InvitationState {
  final InvitationErrorReason reason;

  const InvitationError(this.reason);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvitationError &&
          runtimeType == other.runtimeType &&
          reason == other.reason;

  @override
  int get hashCode => reason.hashCode;
}
