abstract class AuthException implements Exception {
  const AuthException();
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException();
}

class InvalidPinException extends AuthException {
  const InvalidPinException();
}

class NetworkAuthException extends AuthException {
  const NetworkAuthException();
}

class UnknownAuthException extends AuthException {
  const UnknownAuthException();
}
