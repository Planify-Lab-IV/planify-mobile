abstract class AuthException implements Exception {
  const AuthException();
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException();
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
