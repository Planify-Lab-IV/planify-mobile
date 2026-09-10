import 'package:dio/dio.dart';

import '../domain/auth_repository.dart';
import '../domain/user_session.dart';
import 'auth_exceptions.dart';

class HttpAuthRepository implements AuthRepository {
  final Dio dio;
  UserSession? _currentSession;

  HttpAuthRepository({required this.dio});

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

  @override
  Future<UserSession> loginAnonymously({
    required String name,
    required String pin,
    String? eventId,
  }) async {
    final normalizedEventId = eventId?.trim();
    if (normalizedEventId == null || normalizedEventId.isEmpty) {
      throw const UnknownAuthException();
    }

    try {
      final response = await dio.post<dynamic>(
        '/events/$normalizedEventId/participants/anonymous',
        data: {'name': name.trim(), 'pin': pin.trim()},
      );
      final session = _anonymousSessionFromResponse(
        response.data,
        requestedEventId: normalizedEventId,
      );
      _currentSession = session;
      return session;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const InvalidPinException();
      }
      if (error.response?.statusCode == 404) {
        throw const AnonymousEventNotFoundException();
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

  @override
  Future<void> logout() async {
    _currentSession = null;
  }

  @override
  Future<UserSession?> getCurrentSession() async {
    if (_currentSession != null) return _currentSession;

    // Session restoration requires a backend validation endpoint.
    return null;
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

  AnonymousSession _anonymousSessionFromResponse(
    dynamic data, {
    required String requestedEventId,
  }) {
    if (data is! Map) throw const UnknownAuthException();

    final participant = data['participant'];
    final token = data['token'];
    if (participant is! Map || token is! String || token.isEmpty) {
      throw const UnknownAuthException();
    }

    final participantId = participant['id'];
    final eventId = participant['eventId'];
    final username = participant['username'];
    final isAnonymous = participant['isAnonymous'];
    if (participantId is! String ||
        participantId.isEmpty ||
        eventId is! String ||
        eventId.isEmpty ||
        eventId != requestedEventId ||
        username is! String ||
        username.isEmpty ||
        isAnonymous is! bool ||
        !isAnonymous) {
      throw const UnknownAuthException();
    }

    return AnonymousSession(
      participantId: participantId,
      name: username,
      eventId: eventId,
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
