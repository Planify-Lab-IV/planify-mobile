abstract class InvitationException implements Exception {
  const InvitationException();
}

/// El token o formato de la invitación es inválido.
class InvalidInvitationException extends InvitationException {
  const InvalidInvitationException();
}

/// El token de invitación no existe o no fue encontrado.
class InvitationNotFoundException extends InvitationException {
  const InvitationNotFoundException();
}

/// El token de invitación ha expirado o ya no está disponible.
class InvitationExpiredException extends InvitationException {
  const InvitationExpiredException();
}

/// Ocurrió un error de red al intentar resolver la invitación.
class NetworkInvitationException extends InvitationException {
  const NetworkInvitationException();
}
