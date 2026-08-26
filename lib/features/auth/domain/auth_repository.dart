import 'user_session.dart';

abstract class AuthRepository {
  Future<UserSession> login({
    required String identifier,
    required String password,
  });

  Future<UserSession> loginAnonymously({
    required String name,
    required String pin,
    String? eventId,
  });

  Future<void> logout();

  Future<UserSession?> getCurrentSession();
}
