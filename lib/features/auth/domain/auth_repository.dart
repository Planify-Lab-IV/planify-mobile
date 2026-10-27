import 'user_session.dart';

abstract class AuthRepository {
  Future<UserSession> login({
    required String identifier,
    required String password,
  });

  Future<UserSession> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    throw UnsupportedError(
      'Registration is not implemented by this repository.',
    );
  }

  Future<void> requestPasswordReset({required String email});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<UserSession> loginAnonymously({
    required String name,
    required String pin,
    String? eventId,
  });

  Future<void> logout();

  Future<UserSession?> getCurrentSession();
}
