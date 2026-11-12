import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/secure_storage.dart';
import '../../../notifications/domain/notifications_repository.dart';
import '../../../notifications/presentation/controllers/push_device_operations.dart';
import '../../data/auth_exceptions.dart';
import '../../domain/auth_repository.dart';
import '../../domain/user_session.dart';
import 'auth_state.dart';

// en base a una accion, cambia el estado de la pantalla 'login'
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStorage _storage;
  final PushDeviceOperations _pushDeviceOperations;
  final Future<String?> Function() getPushToken;

  AuthNotifier(
    this._repository,
    this._storage, {
    required NotificationsRepository notificationsRepository,
    required this.getPushToken,
    PushDeviceOperations? pushDeviceOperations,
  }) : _pushDeviceOperations =
           pushDeviceOperations ??
           PushDeviceOperations(notificationsRepository),
       super(const AuthInitial());

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

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    try {
      final session = await _repository.register(
        name: name,
        username: username,
        email: email,
        password: password,
      );

      await _storage.saveToken(session.token);

      state = AuthAuthenticated(session);
    } on RegistrationConflictException {
      state = const AuthError(AuthFailureReason.registrationConflict);
    } on InvalidRegistrationDataException {
      state = const AuthError(AuthFailureReason.invalidRegistrationData);
    } on NetworkAuthException {
      state = const AuthError(AuthFailureReason.networkError);
    } catch (_) {
      state = const AuthError(AuthFailureReason.unknown);
    }
  }

  Future<void> loginAnonymously({
    required String name,
    required String pin,
    String? eventId,
  }) async {
    state = const AuthLoading();
    try {
      final session = await _repository.loginAnonymously(
        name: name,
        pin: pin,
        eventId: eventId,
      );

      // Persistencia segura del token (la UI nunca toca _storage directamente)
      await _storage.saveToken(session.token);

      state = AuthAuthenticated(session);
    } on InvalidPinException {
      state = const AuthError(AuthFailureReason.invalidPin);
    } on AnonymousEventNotFoundException {
      state = const AuthError(AuthFailureReason.eventNotFound);
    } on AnonymousEventUnavailableException {
      state = const AuthError(AuthFailureReason.eventUnavailable);
    } on InvalidCredentialsException {
      state = const AuthError(AuthFailureReason.invalidCredentials);
    } on NetworkAuthException {
      state = const AuthError(AuthFailureReason.networkError);
    } catch (_) {
      state = const AuthError(AuthFailureReason.unknown);
    }
  }

  Future<void> logout() async {
    final session = state is AuthAuthenticated
        ? (state as AuthAuthenticated).session
        : null;
    state = const AuthLoading();
    if (session is OrganizerSession) {
      await _unregisterDevice(session.token);
    }
    try {
      await _repository.logout();
    } catch (_) {
      // Continuamos con el borrado local aunque falle el logout remoto
    }

    try {
      await _storage.deleteToken();
      state = const AuthUnauthenticated();
    } catch (_) {
      // No confirmamos el logout si el token puede seguir almacenado.
      state = const AuthError(AuthFailureReason.unknown);
    }
  }

  Future<void> _unregisterDevice(String sessionToken) async {
    try {
      const timeout = Duration(seconds: 2);
      final elapsed = Stopwatch()..start();
      String? pushToken;
      try {
        pushToken = await getPushToken().timeout(timeout);
      } on TimeoutException {
        pushToken = _pushDeviceOperations.lastPushToken;
      }
      if (pushToken == null || pushToken.trim().isEmpty) return;
      final remaining = timeout - elapsed.elapsed;
      final operation = _pushDeviceOperations.unregister(
        pushToken,
        sessionToken,
      );
      if (remaining <= Duration.zero) {
        unawaited(operation.catchError((_) {}));
      } else {
        await operation.timeout(remaining);
      }
    } catch (_) {
      // Un fallo de red no debe impedir el cierre local de sesión.
    }
  }

  Future<void> checkAuthStatus() async {
    state = const AuthCheckingInitialSession();
    try {
      final session = await _repository.getCurrentSession();
      if (session != null) {
        state = AuthAuthenticated(session);
      } else {
        state = const AuthUnauthenticated();
      }
    } on InvalidStoredSessionException {
      try {
        await _storage.deleteToken();
        state = const AuthUnauthenticated();
      } catch (_) {
        // No confirmamos la sesión como cerrada si el token sigue almacenado.
        state = const AuthError(AuthFailureReason.unknown);
      }
    } on NetworkAuthException {
      // El token puede seguir siendo válido: se conserva para reintentar.
      state = const AuthError(AuthFailureReason.networkError);
    } catch (_) {
      state = const AuthError(AuthFailureReason.unknown);
    }
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthInitial();
    }
  }

  void updateSessionName(String name) {
    final currentState = state;
    if (currentState is! AuthAuthenticated ||
        currentState.session is! OrganizerSession) {
      return;
    }

    final session = currentState.session as OrganizerSession;
    state = AuthAuthenticated(
      OrganizerSession(
        userId: session.userId,
        name: name,
        email: session.email,
        username: session.username,
        token: session.token,
      ),
    );
  }
}
