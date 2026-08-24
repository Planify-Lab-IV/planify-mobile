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

    final trimmedIdentifier = identifier.trim();
    final trimmedPassword = password.trim();

    // Simulación de error de red para testing
    if (trimmedIdentifier == 'network.error@planify.com') {
      throw const NetworkAuthException();
    }

    if (trimmedIdentifier.isEmpty || trimmedPassword.length < 6) {
      throw const InvalidCredentialsException();
    }

    final session = UserSession(
      userId: 'org-${DateTime.now().millisecondsSinceEpoch}',
      email: trimmedIdentifier,
      name: trimmedIdentifier.contains('@')
          ? trimmedIdentifier.split('@').first
          : trimmedIdentifier,
      role: UserRole.organizer,
      token:
          'fake-org-token-${DateTime.now().millisecondsSinceEpoch}',
    );

    _currentSession = session;
    return session;
  }

  @override
  Future<UserSession> loginAnonymously() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    final session = UserSession(
      userId: 'anon-${DateTime.now().millisecondsSinceEpoch}',
      email: '',
      name: '',
      role: UserRole.anonymous,
      token: 'fake-guest-token-${DateTime.now().millisecondsSinceEpoch}',
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
