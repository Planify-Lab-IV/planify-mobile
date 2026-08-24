import '../domain/auth_repository.dart';
import '../domain/user_session.dart';
import 'auth_exceptions.dart';

class FakeAuthRepository implements AuthRepository {
  final Duration delay;
  UserSession? _currentSession;

  FakeAuthRepository({this.delay = const Duration(milliseconds: 800)});

  @override
  Future<UserSession> login({
    required String identifier,
    required String password,
  }) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    final trimmedIdentifier = identifier.trim().toLowerCase();
    final trimmedPassword = password.trim();

    // Simulación de error de red para testing
    if (trimmedIdentifier == 'network.error@planify.com') {
      throw const NetworkAuthException();
    }

    // Regla de login fake: cualquier email con @planify.com o usuario organizador con contraseña >= 6 caracteres
    final isValidOrganizer =
        (trimmedIdentifier == 'organizador@planify.com' ||
            trimmedIdentifier.endsWith('@planify.com') ||
            trimmedIdentifier == 'organizador') &&
        trimmedPassword.length >= 6;

    if (!isValidOrganizer) {
      throw const InvalidCredentialsException();
    }

    final session = UserSession(
      userId: 'org-12345',
      email: trimmedIdentifier.contains('@')
          ? trimmedIdentifier
          : '$trimmedIdentifier@planify.com',
      name: 'Organizador Planify',
      role: UserRole.organizer,
      token:
          'fake-jwt-token-org-12345-${DateTime.now().millisecondsSinceEpoch}',
    );

    _currentSession = session;
    return session;
  }

  @override
  Future<void> logout() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    _currentSession = null;
  }

  @override
  Future<UserSession?> getCurrentSession() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return _currentSession;
  }
}
