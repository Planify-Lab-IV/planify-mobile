import 'package:dio/dio.dart';

import '../domain/group.dart';
import '../domain/groups_repository.dart';
import 'group_exceptions.dart';

class HttpGroupsRepository implements GroupsRepository {
  final Dio dio;

  HttpGroupsRepository({required this.dio});

  @override
  Future<List<Group>> getMyGroups() async {
    try {
      final response = await dio.get<dynamic>('/me/groups');
      return _groupsFromResponse(response.data);
    } on DioException catch (error) {
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

  List<Group> _groupsFromResponse(dynamic data) {
    if (data is! List) throw const InvalidGroupsResponseException();

    return data.map(_groupFromResponse).toList(growable: false);
  }

  Group _groupFromResponse(dynamic data) {
    if (data is! Map) throw const InvalidGroupsResponseException();

    final id = data['id'];
    final name = data['name'];
    final memberCount = data['memberCount'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.isEmpty ||
        memberCount is! int ||
        memberCount < 0) {
      throw const InvalidGroupsResponseException();
    }

    return Group(id: id, name: name, memberCount: memberCount);
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
