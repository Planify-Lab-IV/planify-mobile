import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/groups/data/group_exceptions.dart';
import 'package:planify/features/groups/data/http_group_management_repository.dart';

void main() {
  Dio resolving({
    required int statusCode,
    void Function(RequestOptions options)? inspect,
  }) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          inspect?.call(options);
          handler.resolve(
            Response<void>(requestOptions: options, statusCode: statusCode),
          );
        },
      ),
    );
    return dio;
  }

  Dio rejecting({required int statusCode}) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<void>(
              requestOptions: options,
              statusCode: statusCode,
            ),
          ),
        ),
      ),
    );
    return dio;
  }

  Dio networkFailing(DioExceptionType type) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) =>
            handler.reject(DioException(requestOptions: options, type: type)),
      ),
    );
    return dio;
  }

  group('HttpGroupManagementRepository', () {
    test('adds a member with the documented endpoint and body', () async {
      RequestOptions? request;
      final repository = HttpGroupManagementRepository(
        dio: resolving(
          statusCode: 204,
          inspect: (options) => request = options,
        ),
      );

      await repository.addMember(groupId: 'group-1', userId: 'user-2');

      expect(request?.method, 'POST');
      expect(request?.path, '/groups/group-1/members');
      expect(request?.data, {'userId': 'user-2'});
    });

    test('renames a group with the documented endpoint and body', () async {
      RequestOptions? request;
      final repository = HttpGroupManagementRepository(
        dio: resolving(
          statusCode: 200,
          inspect: (options) => request = options,
        ),
      );

      await repository.renameGroup(groupId: 'group-1', name: 'Viaje');

      expect(request?.method, 'PATCH');
      expect(request?.path, '/groups/group-1');
      expect(request?.data, {'name': 'Viaje'});
    });

    test('leaves a group with the documented endpoint', () async {
      RequestOptions? request;
      final repository = HttpGroupManagementRepository(
        dio: resolving(
          statusCode: 204,
          inspect: (options) => request = options,
        ),
      );

      await repository.leaveGroup('group-1');

      expect(request?.method, 'DELETE');
      expect(request?.path, '/groups/group-1/members/me');
      expect(request?.data, isNull);
    });

    test('maps 400, 403, and 404 to group management exceptions', () async {
      await expectLater(
        HttpGroupManagementRepository(
          dio: rejecting(statusCode: 400),
        ).addMember(groupId: 'group-1', userId: 'user-2'),
        throwsA(isA<InvalidGroupDataException>()),
      );
      await expectLater(
        HttpGroupManagementRepository(
          dio: rejecting(statusCode: 403),
        ).renameGroup(groupId: 'group-1', name: 'Viaje'),
        throwsA(isA<GroupForbiddenException>()),
      );
      await expectLater(
        HttpGroupManagementRepository(
          dio: rejecting(statusCode: 404),
        ).leaveGroup('group-1'),
        throwsA(isA<GroupNotFoundException>()),
      );
    });

    test(
      'maps connection and timeout failures to a network exception',
      () async {
        for (final type in [
          DioExceptionType.connectionTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.connectionError,
        ]) {
          await expectLater(
            HttpGroupManagementRepository(
              dio: networkFailing(type),
            ).leaveGroup('group-1'),
            throwsA(isA<NetworkGroupsException>()),
          );
        }
      },
    );
  });
}
