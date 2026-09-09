import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/groups/data/group_exceptions.dart';
import 'package:planify/features/groups/data/http_groups_repository.dart';

void main() {
  group('HttpGroupsRepository', () {
    Dio dioResolving(dynamic body, void Function(RequestOptions)? inspect) {
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

    test('requests and maps the authenticated user groups', () async {
      RequestOptions? request;
      final repository = HttpGroupsRepository(
        dio: dioResolving([
          {'id': 'grp-1', 'name': 'Amigos', 'memberCount': 3},
        ], (options) => request = options),
      );

      final groups = await repository.getMyGroups();

      expect(request?.method, 'GET');
      expect(request?.path, '/me/groups');
      expect(groups, hasLength(1));
      expect(groups.single.id, 'grp-1');
      expect(groups.single.name, 'Amigos');
      expect(groups.single.memberCount, 3);
    });

    test('rejects a malformed successful response', () async {
      final repository = HttpGroupsRepository(
        dio: dioResolving({'id': 'grp-1'}, null),
      );

      expect(
        repository.getMyGroups,
        throwsA(isA<InvalidGroupsResponseException>()),
      );
    });

    test('maps connection errors to a network exception', () async {
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
      final repository = HttpGroupsRepository(dio: dio);

      expect(
        repository.getMyGroups,
        throwsA(isA<NetworkGroupsException>()),
      );
    });
  });
}
