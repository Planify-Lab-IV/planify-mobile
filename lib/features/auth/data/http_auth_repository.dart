import 'package:dio/dio.dart';

import '../domain/auth_repository.dart';
import '../domain/user_session.dart';
import 'auth_exceptions.dart';

class HttpAuthRepository implements AuthRepository {
  final Dio dio;
  final AuthRepository anonymousRepository;
  UserSession? _currentSession;

  HttpAuthRepository({required this.dio, required this.anonymousRepository});

  @override
  Future<UserSession> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await dio.post<dynamic>(
        '/auth/login',
        data: {'identifier': identifier, 'password': password},
      );

      final session = _organizerSessionFromResponse(response.data);
      _currentSession = session;
      return session;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const InvalidCredentialsException();
      }
      if (_isNetworkError(error)) {
        throw const NetworkAuthException();
      }
      throw const UnknownAuthException();
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const UnknownAuthException();
    }
  }

  // este endpoint va a ser modificado en otro ticket
  @override
  Future<UserSession> loginAnonymously({
    required String name,
    required String pin,
    String? eventId,
  }) async {
    final session = await anonymousRepository.loginAnonymously(
      name: name,
      pin: pin,
      eventId: eventId,
    );
    _currentSession = session;
    return session;
  }

  @override
  Future<void> logout() async {
    _currentSession = null;
    await anonymousRepository.logout();
  }

  @override
  Future<UserSession?> getCurrentSession() async {
    if (_currentSession != null) return _currentSession;

    // Organizer restoration must use a future backend validation endpoint.
    return anonymousRepository.getCurrentSession();
  }

  OrganizerSession _organizerSessionFromResponse(dynamic data) {
    if (data is! Map) throw const UnknownAuthException();

    final user = data['user'];
    final token = data['token'];
    if (user is! Map || token is! String || token.isEmpty) {
      throw const UnknownAuthException();
    }

    final userId = user['id'];
    final name = user['name'];
    final username = user['username'];
    final email = user['email'];
    if (userId is! String ||
        userId.isEmpty ||
        name is! String ||
        name.isEmpty ||
        username is! String ||
        username.isEmpty ||
        email is! String ||
        email.isEmpty) {
      throw const UnknownAuthException();
    }

    return OrganizerSession(
      userId: userId,
      name: name,
      username: username,
      email: email,
      token: token,
    );
  }

  bool _isNetworkError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }
}
