import '../../domain/user_session.dart';

enum AuthFailureReason {
  invalidCredentials,
  networkError,
  unknown,
}

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  /*
  esto es un constructor constante, por lo que el objeto se crea una sola vez y no puede cambiar.
  por ende, cada vez que se llama nuevamente al AuthInitial() con const adelante,
  simplemente se reusa la misma instancia
   */
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserSession session;
  const AuthAuthenticated(this.session);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated &&
          runtimeType == other.runtimeType &&
          session == other.session;

  @override
  int get hashCode => session.hashCode;
}

class AuthError extends AuthState {
  final AuthFailureReason reason;
  const AuthError(this.reason);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          runtimeType == other.runtimeType &&
          reason == other.reason;

  @override
  int get hashCode => reason.hashCode;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
