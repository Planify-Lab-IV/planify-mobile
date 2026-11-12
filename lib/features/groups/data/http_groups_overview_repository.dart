import 'package:dio/dio.dart';

import '../../events/domain/event_status.dart';
import '../domain/group_overview.dart';
import '../domain/groups_overview_repository.dart';
import 'group_exceptions.dart';

class HttpGroupsOverviewRepository implements GroupsOverviewRepository {
  final Dio dio;

  HttpGroupsOverviewRepository({required this.dio});

  @override
  Future<List<GroupOverview>> getMyGroupsOverview() async {
    try {
      final response = await dio.get<dynamic>('/me/groups/overview');
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

  List<GroupOverview> _groupsFromResponse(dynamic data) {
    if (data is! List) throw const InvalidGroupsResponseException();

    return data.map(_groupFromResponse).toList(growable: false);
  }

  GroupOverview _groupFromResponse(dynamic data) {
    if (data is! Map) throw const InvalidGroupsResponseException();

    final events = data['events'];
    if (events is! List) throw const InvalidGroupsResponseException();

    return GroupOverview(
      id: _requiredString(data, 'id'),
      name: _requiredString(data, 'name'),
      memberCount: _requiredNonNegativeInt(data, 'memberCount'),
      events: events.map(_eventFromResponse).toList(growable: false),
    );
  }

  GroupEventSummary _eventFromResponse(dynamic data) {
    if (data is! Map) throw const InvalidGroupsResponseException();

    return GroupEventSummary(
      id: _requiredString(data, 'id'),
      name: _requiredString(data, 'name'),
      location: _requiredString(data, 'location'),
      status: EventStatus.fromApi(_requiredString(data, 'status')),
      startDateTime: _nullableLocalDateTime(data, 'startDateTime'),
    );
  }

  String _requiredString(Map<dynamic, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw const InvalidGroupsResponseException();
    }
    return value;
  }

  int _requiredNonNegativeInt(Map<dynamic, dynamic> data, String key) {
    final value = data[key];
    if (value is! int || value < 0) {
      throw const InvalidGroupsResponseException();
    }
    return value;
  }

  DateTime? _nullableLocalDateTime(Map<dynamic, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is! String) throw const InvalidGroupsResponseException();

    final dateTime = DateTime.tryParse(value);
    if (dateTime == null) throw const InvalidGroupsResponseException();
    return dateTime.toLocal();
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
