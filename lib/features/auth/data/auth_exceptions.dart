abstract class AuthException implements Exception {
  const AuthException();
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException();
}

class RegistrationConflictException extends AuthException {
  const RegistrationConflictException();
}

class InvalidRegistrationDataException extends AuthException {
  const InvalidRegistrationDataException();
}

class InvalidStoredSessionException extends AuthException {
  const InvalidStoredSessionException();
}

class InvalidPinException extends AuthException {
  const InvalidPinException();
}

class AnonymousEventNotFoundException extends AuthException {
  const AnonymousEventNotFoundException();
}

class AnonymousEventUnavailableException extends AuthException {
  const AnonymousEventUnavailableException();
}

class NetworkAuthException extends AuthException {
  const NetworkAuthException();
}

class UnknownAuthException extends AuthException {
  const UnknownAuthException();
}
