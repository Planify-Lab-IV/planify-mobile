import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/secure_storage.dart';
import '../../data/auth_exceptions.dart';
import '../../domain/auth_repository.dart';
import 'auth_state.dart';

// en base a una accion, cambia el estado de la pantalla 'login'
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStorage _storage;

  AuthNotifier(this._repository, this._storage) : super(const AuthInitial());

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    // cuando se reasigna la variable state, riverpod le avisa a la pantalla para que se redibuje sola
    state = const AuthLoading();

    try {
      final session = await _repository.login(
        identifier: identifier,
        password: password,
      );

      // Persistencia segura del token (la UI nunca toca _storage directamente)
      await _storage.saveToken(session.token);

      state = AuthAuthenticated(session);
    } on InvalidCredentialsException {
      state = const AuthError(AuthFailureReason.invalidCredentials);
    } on NetworkAuthException {
      state = const AuthError(AuthFailureReason.networkError);
    } catch (_) {
      state = const AuthError(AuthFailureReason.unknown);
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _repository.logout();
    } catch (_) {
      // Continuamos con el borrado local aunque falle el logout remoto
    } finally {
      await _storage.deleteToken();
      state = const AuthUnauthenticated();
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        state = const AuthUnauthenticated();
        return;
      }

      final session = await _repository.getCurrentSession();
      if (session != null) {
        state = AuthAuthenticated(session);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthInitial();
    }
  }
}
