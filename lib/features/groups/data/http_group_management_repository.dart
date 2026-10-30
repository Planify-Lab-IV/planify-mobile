import 'package:dio/dio.dart';

import '../domain/group_management_repository.dart';
import 'group_exceptions.dart';

class HttpGroupManagementRepository implements GroupManagementRepository {
  final Dio dio;

  HttpGroupManagementRepository({required this.dio});

  @override
  Future<void> addMember({required String groupId, required String userId}) {
    return _execute(
      () =>
          dio.post<void>('/groups/$groupId/members', data: {'userId': userId}),
    );
  }

  @override
  Future<void> renameGroup({required String groupId, required String name}) {
    return _execute(
      () => dio.patch<void>('/groups/$groupId', data: {'name': name}),
    );
  }

  @override
  Future<void> leaveGroup(String groupId) {
    return _execute(() => dio.delete<void>('/groups/$groupId/members/me'));
  }

  Future<void> _execute(Future<Object?> Function() operation) async {
    try {
      await operation();
    } on DioException catch (error) {
      switch (error.response?.statusCode) {
        case 400:
          throw const InvalidGroupDataException();
        case 403:
          throw const GroupForbiddenException();
        case 404:
          throw const GroupNotFoundException();
      }
      if (_isNetworkError(error)) {
        throw const NetworkGroupsException();
      }
      throw const InvalidGroupsResponseException();
    } on GroupsException {
      rethrow;
    } catch (_) {
      throw const InvalidGroupsResponseException();
    }
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
