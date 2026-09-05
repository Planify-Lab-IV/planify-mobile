import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/auth/data/auth_exceptions.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/data/http_auth_repository.dart';
import 'package:planify/features/auth/domain/user_session.dart';

void main() {
  group('HttpAuthRepository', () {
    const responseData = {
      'user': {
        'id': 'uuid-organizer-1',
        'name': 'Dev One',
        'username': 'dev1',
        'email': 'dev1@planify.dev',
      },
      'token': 'backend-jwt-token',
    };

    HttpAuthRepository repositoryWith(Dio dio) {
      return HttpAuthRepository(
        dio: dio,
        anonymousRepository: FakeAuthRepository(delay: Duration.zero),
      );
    }

    Dio dioResolving(
      Map<String, dynamic> body,
      void Function(RequestOptions)? inspect,
    ) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            inspect?.call(options);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: body,
              ),
            );
          },
        ),
      );
      return dio;
    }

    test(
      'sends an email unchanged as identifier and maps canonical user data',
      () async {
        RequestOptions? request;
        final repository = repositoryWith(
          dioResolving(responseData, (options) => request = options),
        );

        final session = await repository.login(
          identifier: 'dev1@planify.dev',
          password: 'DevPass123!',
        );

        expect(request?.method, 'POST');
        expect(request?.path, '/auth/login');
        expect(request?.data, {
          'identifier': 'dev1@planify.dev',
          'password': 'DevPass123!',
        });
        expect(session, isA<OrganizerSession>());
        final organizer = session as OrganizerSession;
        expect(organizer.userId, 'uuid-organizer-1');
        expect(organizer.name, 'Dev One');
        expect(organizer.username, 'dev1');
        expect(organizer.email, 'dev1@planify.dev');
        expect(organizer.token, 'backend-jwt-token');
        expect(organizer.role, UserRole.organizer);
      },
    );

    test('sends a username unchanged as identifier', () async {
      RequestOptions? request;
      final repository = repositoryWith(
        dioResolving(responseData, (options) => request = options),
      );

      await repository.login(identifier: 'dev1', password: 'DevPass123!');

      expect(request?.data, {'identifier': 'dev1', 'password': 'DevPass123!'});
    });

    test('maps a 401 response to invalid credentials', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 401,
              ),
            ),
          ),
        ),
      );

      expect(
        () => repositoryWith(dio).login(identifier: 'dev1', password: 'wrong'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });

    test('maps connection errors to network errors', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          ),
        ),
      );

      expect(
        () => repositoryWith(
          dio,
        ).login(identifier: 'dev1', password: 'DevPass123!'),
        throwsA(isA<NetworkAuthException>()),
      );
    });

    test('rejects malformed success responses', () async {
      final repository = repositoryWith(dioResolving({'token': 'token'}, null));

      expect(
        () => repository.login(identifier: 'dev1', password: 'DevPass123!'),
        throwsA(isA<UnknownAuthException>()),
      );
    });
  });
}
