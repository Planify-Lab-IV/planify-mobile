import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/auth_exceptions.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/data/http_auth_repository.dart';
import 'package:planify/features/auth/domain/auth_repository.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:planify/features/auth/presentation/controllers/auth_state.dart';
import 'package:planify/features/notifications/data/fake_notifications_repository.dart';

import '../helpers/fake_push_messaging_service.dart';

void main() {
  group('AuthNotifier', () {
    late FakeAuthRepository repository;
    late FakeSecureStorage storage;
    late FakeNotificationsRepository notificationsRepository;
    late FakePushMessagingService pushMessagingService;
    late AuthNotifier notifier;

    AuthNotifier createNotifier(
      AuthRepository authRepository,
      SecureStorage authStorage,
    ) {
      return AuthNotifier(
        authRepository,
        authStorage,
        notificationsRepository: notificationsRepository,
        getPushToken: pushMessagingService.getToken,
      );
    }

    setUp(() {
      storage = FakeSecureStorage();
      repository = FakeAuthRepository(storage: storage, delay: Duration.zero);
      notificationsRepository = FakeNotificationsRepository(
        delay: Duration.zero,
      );
      pushMessagingService = FakePushMessagingService();
      notifier = createNotifier(repository, storage);
    });

    tearDown(() => pushMessagingService.dispose());

    test('estado inicial es AuthInitial', () {
      expect(notifier.state, isA<AuthInitial>());
    });

    test(
      'solo checkAuthStatus emite el estado de verificación inicial',
      () async {
        final checking = notifier.checkAuthStatus();
        expect(notifier.state, isA<AuthCheckingInitialSession>());
        await checking;
        expect(notifier.state, isA<AuthUnauthenticated>());

        final login = notifier.login(
          identifier: 'lucas',
          password: 'password123',
        );
        expect(notifier.state, isA<AuthLoading>());
        await login;
        final logout = notifier.logout();
        expect(notifier.state, isA<AuthLoading>());
        await logout;
        final register = notifier.register(
          name: 'Lucía',
          username: 'lucia',
          email: 'lucia@planify.com',
          password: 'password123',
        );
        expect(notifier.state, isA<AuthLoading>());
        await register;
        final anonymous = notifier.loginAnonymously(
          name: 'Invitado',
          pin: '1234',
        );
        expect(notifier.state, isA<AuthLoading>());
        await anonymous;
      },
    );

    test(
      'login exitoso guarda token y cambia a AuthAuthenticated con OrganizerSession',
      () async {
        await notifier.login(
          identifier: 'lucas@gmail.com',
          password: 'password123',
        );

        expect(notifier.state, isA<AuthAuthenticated>());
        final authState = notifier.state as AuthAuthenticated;
        expect(authState.session, isA<OrganizerSession>());
        final orgSession = authState.session as OrganizerSession;
        expect(orgSession.email, equals('lucas@gmail.com'));
        expect(orgSession.isOrganizer, isTrue);

        final storedToken = await storage.getToken();
        expect(storedToken, equals(orgSession.token));
      },
    );

    test(
      'loginAnonymously guarda token y cambia a AuthAuthenticated con AnonymousSession',
      () async {
        await notifier.loginAnonymously(name: 'Lucas', pin: '1234');

        expect(notifier.state, isA<AuthAuthenticated>());
        final authState = notifier.state as AuthAuthenticated;
        expect(authState.session, isA<AnonymousSession>());
        final anonSession = authState.session as AnonymousSession;
        expect(anonSession.name, equals('Lucas'));
        expect(anonSession.isAnonymous, isTrue);
        expect(anonSession.eventId, equals('evt-fake-demo'));

        final storedToken = await storage.getToken();
        expect(storedToken, equals(anonSession.token));
        expect(storedToken!.contains('1234'), isFalse);
      },
    );

    test(
      'loginAnonymously con PIN inválido cambia a AuthError(invalidPin) y no guarda token',
      () async {
        await notifier.loginAnonymously(name: 'Lucas', pin: '9999');

        expect(notifier.state, isA<AuthError>());
        final errorState = notifier.state as AuthError;
        expect(errorState.reason, equals(AuthFailureReason.invalidPin));

        final storedToken = await storage.getToken();
        expect(storedToken, isNull);
      },
    );

    test(
      'login fallido cambia a AuthError con motivo y no guarda token',
      () async {
        await notifier.login(
          identifier: 'invalido@externo.com',
          password: '123',
        );

        expect(notifier.state, isA<AuthError>());
        final errorState = notifier.state as AuthError;
        expect(errorState.reason, equals(AuthFailureReason.invalidCredentials));

        final storedToken = await storage.getToken();
        expect(storedToken, isNull);
      },
    );

    test(
      'register exitoso guarda token y cambia a AuthAuthenticated con OrganizerSession',
      () async {
        await notifier.register(
          name: 'Lucía Planes',
          username: 'lucia_planes',
          email: 'lucia@planify.com',
          password: 'password123',
        );

        expect(notifier.state, isA<AuthAuthenticated>());
        final authState = notifier.state as AuthAuthenticated;
        expect(authState.session, isA<OrganizerSession>());
        final session = authState.session as OrganizerSession;
        expect(session.name, 'Lucía Planes');
        expect(session.username, 'lucia_planes');
        expect(session.email, 'lucia@planify.com');
        expect(await storage.getToken(), session.token);
      },
    );

    test(
      'register con conflicto conserva el token y cambia a AuthError específico',
      () async {
        await storage.saveToken('existing-token');
        notifier = createNotifier(
          FakeAuthRepository(
            storage: storage,
            delay: Duration.zero,
            usedUsernames: const ['usuario_ocupado'],
          ),
          storage,
        );

        await notifier.register(
          name: 'Lucía',
          username: 'usuario_ocupado',
          email: 'lucia@planify.com',
          password: 'password123',
        );

        expect(
          notifier.state,
          const AuthError(AuthFailureReason.registrationConflict),
        );
        expect(await storage.getToken(), 'existing-token');
      },
    );

    test(
      'register con datos inválidos cambia a AuthError específico',
      () async {
        await notifier.register(
          name: '',
          username: 'lucia',
          email: 'lucia@planify.com',
          password: 'password123',
        );

        expect(
          notifier.state,
          const AuthError(AuthFailureReason.invalidRegistrationData),
        );
        expect(await storage.getToken(), isNull);
      },
    );

    test('register con error de red cambia a AuthError de red', () async {
      await notifier.register(
        name: 'Lucía',
        username: 'lucia',
        email: 'network.error@planify.com',
        password: 'password123',
      );

      expect(notifier.state, const AuthError(AuthFailureReason.networkError));
      expect(await storage.getToken(), isNull);
    });

    test(
      'register con error desconocido cambia a AuthError desconocido',
      () async {
        notifier = createNotifier(
          _ThrowingRegisterRepository(
            storage: storage,
            exception: const UnknownAuthException(),
          ),
          storage,
        );

        await notifier.register(
          name: 'Lucía',
          username: 'lucia',
          email: 'lucia@planify.com',
          password: 'password123',
        );

        expect(notifier.state, const AuthError(AuthFailureReason.unknown));
        expect(await storage.getToken(), isNull);
      },
    );

    test('logout elimina token y cambia a AuthUnauthenticated', () async {
      await notifier.login(
        identifier: 'lucas@gmail.com',
        password: 'password123',
      );

      await notifier.logout();

      expect(notifier.state, isA<AuthUnauthenticated>());
      final storedToken = await storage.getToken();
      expect(storedToken, isNull);
      expect(notificationsRepository.unregisteredPushTokens, [
        'fake-push-token',
      ]);
    });

    test('logout continúa si no puede desregistrar el dispositivo', () async {
      notificationsRepository = FakeNotificationsRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      );
      notifier = createNotifier(repository, storage);
      await notifier.login(
        identifier: 'lucas@gmail.com',
        password: 'password123',
      );

      await notifier.logout();

      expect(notifier.state, isA<AuthUnauthenticated>());
      expect(await storage.getToken(), isNull);
    });

    test(
      'no inicia un desregistro tardío si obtener el token excede el timeout',
      () async {
        final token = Completer<String?>();
        notifier = AuthNotifier(
          repository,
          storage,
          notificationsRepository: notificationsRepository,
          getPushToken: () => token.future,
        );
        await notifier.login(identifier: 'lucas', password: 'password123');
        await notifier.logout();
        expect(notifier.state, isA<AuthUnauthenticated>());
        token.complete('late-token');
        await Future<void>.delayed(Duration.zero);
        expect(notificationsRepository.unregisteredPushTokens, isEmpty);
      },
    );

    test('logout informa un error si no puede borrar el token local', () async {
      final failingStorage = _FailingDeleteSecureStorage();
      final failingRepository = FakeAuthRepository(
        storage: failingStorage,
        delay: Duration.zero,
      );
      notifier = createNotifier(failingRepository, failingStorage);

      await notifier.login(
        identifier: 'lucas@gmail.com',
        password: 'password123',
      );

      await notifier.logout();

      expect(notifier.state, const AuthError(AuthFailureReason.unknown));
      expect(await failingStorage.getToken(), isNotNull);
    });

    test('checkAuthStatus clears an invalid stored token', () async {
      await storage.saveToken('expired-jwt-token');
      notifier = createNotifier(
        _ThrowingCurrentSessionRepository(
          storage: storage,
          exception: const InvalidStoredSessionException(),
        ),
        storage,
      );

      await notifier.checkAuthStatus();

      expect(notifier.state, isA<AuthUnauthenticated>());
      expect(await storage.getToken(), isNull);
    });

    test('checkAuthStatus keeps the token after a network failure', () async {
      await storage.saveToken('stored-jwt-token');
      notifier = createNotifier(
        _ThrowingCurrentSessionRepository(
          storage: storage,
          exception: const NetworkAuthException(),
        ),
        storage,
      );

      await notifier.checkAuthStatus();

      expect(notifier.state, const AuthError(AuthFailureReason.networkError));
      expect(await storage.getToken(), 'stored-jwt-token');
    });

    test(
      'checkAuthStatus reports an error if it cannot clear an invalid token',
      () async {
        final failingStorage = _FailingDeleteSecureStorage();
        await failingStorage.saveToken('expired-jwt-token');
        notifier = createNotifier(
          _ThrowingCurrentSessionRepository(
            storage: failingStorage,
            exception: const InvalidStoredSessionException(),
          ),
          failingStorage,
        );

        await notifier.checkAuthStatus();

        expect(notifier.state, const AuthError(AuthFailureReason.unknown));
        expect(await failingStorage.getToken(), 'expired-jwt-token');
      },
    );

    test(
      'persists the token returned by the anonymous HTTP endpoint',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'participant': {
                    'id': 'participant-a',
                    'eventId': 'event-a',
                    'username': 'Gil',
                    'isAnonymous': true,
                  },
                  'token': 'real-anonymous-token',
                },
              ),
            ),
          ),
        );
        notifier = createNotifier(
          HttpAuthRepository(dio: dio, storage: storage),
          storage,
        );

        await notifier.loginAnonymously(
          name: 'Gil',
          pin: '1234',
          eventId: 'event-a',
        );

        expect(notifier.state, isA<AuthAuthenticated>());
        final session = (notifier.state as AuthAuthenticated).session;
        expect(session, isA<AnonymousSession>());
        expect((session as AnonymousSession).eventId, 'event-a');
        expect(await storage.getToken(), 'real-anonymous-token');
      },
    );

    test(
      'does not overwrite storage when the anonymous event does not exist',
      () async {
        await storage.saveToken('existing-token');
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 404,
                ),
              ),
            ),
          ),
        );
        notifier = createNotifier(
          HttpAuthRepository(dio: dio, storage: storage),
          storage,
        );

        await notifier.loginAnonymously(
          name: 'Gil',
          pin: '1234',
          eventId: 'event-missing',
        );

        expect(
          notifier.state,
          const AuthError(AuthFailureReason.eventNotFound),
        );
        expect(await storage.getToken(), 'existing-token');
      },
    );

    test(
      'sets state to AuthError(eventUnavailable) when event is unavailable (409)',
      () async {
        await storage.saveToken('existing-token');
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 409,
                ),
              ),
            ),
          ),
        );
        notifier = createNotifier(
          HttpAuthRepository(dio: dio, storage: storage),
          storage,
        );

        await notifier.loginAnonymously(
          name: 'Gil',
          pin: '1234',
          eventId: 'event-unavailable',
        );

        expect(
          notifier.state,
          const AuthError(AuthFailureReason.eventUnavailable),
        );
        expect(await storage.getToken(), 'existing-token');
      },
    );
  });
}

class _FailingDeleteSecureStorage implements SecureStorage {
  String? _token;

  @override
  Future<void> deleteToken() async {
    throw StateError('No se pudo eliminar el token');
  }

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }
}

class _ThrowingCurrentSessionRepository extends FakeAuthRepository {
  final AuthException exception;

  _ThrowingCurrentSessionRepository({
    required SecureStorage storage,
    required this.exception,
  }) : super(storage: storage, delay: Duration.zero);

  @override
  Future<UserSession?> getCurrentSession() async {
    throw exception;
  }
}

class _ThrowingRegisterRepository extends FakeAuthRepository {
  final AuthException exception;

  _ThrowingRegisterRepository({
    required SecureStorage storage,
    required this.exception,
  }) : super(storage: storage, delay: Duration.zero);

  @override
  Future<UserSession> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    throw exception;
  }
}
