import 'package:dio/dio.dart';

import '../domain/activity_entry.dart';
import '../domain/activity_log_repository.dart';
import '../domain/activity_type.dart';
import '../domain/unread_counts.dart';
import 'activity_log_exceptions.dart';

class HttpActivityLogRepository implements ActivityLogRepository {
  final Dio dio;
  HttpActivityLogRepository({required this.dio});

  @override
  Future<UnreadCounts> getUnreadCounts() async {
    try {
      final response = await dio.get<dynamic>('/me/unread-counts');
      final data = response.data;
      if (data is! Map) {
        throw const InvalidActivityLogResponseException();
      }
      return UnreadCounts(
        byEvent: _countsFromResponse(data['events'], 'eventId'),
        byGroup: _countsFromResponse(data['groups'], 'groupId'),
      );
    } on DioException catch (error) {
      if (_isNetworkError(error)) throw const NetworkActivityLogException();
      throw const InvalidActivityLogResponseException();
    } on ActivityLogException {
      rethrow;
    } catch (_) {
      throw const InvalidActivityLogResponseException();
    }
  }

  @override
  Future<void> markEventAsRead(String eventId) async {
    final normalizedEventId = eventId.trim();
    if (normalizedEventId.isEmpty) {
      throw const InvalidActivityLogResponseException();
    }
    try {
      final response = await dio.post<void>(
        '/events/$normalizedEventId/activity-log/read',
      );
      if (response.statusCode != 204) {
        throw const InvalidActivityLogResponseException();
      }
    } on DioException catch (error) {
      if (_isNetworkError(error)) throw const NetworkActivityLogException();
      throw const InvalidActivityLogResponseException();
    } on ActivityLogException {
      rethrow;
    } catch (_) {
      throw const InvalidActivityLogResponseException();
    }
  }

  Map<String, int> _countsFromResponse(dynamic data, String idKey) {
    if (data is! List) throw const InvalidActivityLogResponseException();
    final counts = <String, int>{};
    for (final entry in data) {
      if (entry is! Map || !_isNonEmptyString(entry[idKey])) {
        throw const InvalidActivityLogResponseException();
      }
      final count = entry['unreadCount'];
      if (count is! int || count < 0) {
        throw const InvalidActivityLogResponseException();
      }
      counts[entry[idKey] as String] = count;
    }
    return counts;
  }

  @override
  Future<List<ActivityEntry>> listEventActivity(String eventId) async {
    final normalizedEventId = eventId.trim();
    if (normalizedEventId.isEmpty) {
      throw const InvalidActivityLogResponseException();
    }

    try {
      final response = await dio.get<dynamic>(
        '/events/$normalizedEventId/activity-log',
      );
      return _entriesFromResponse(response.data);
    } on DioException catch (error) {
      if (_isNetworkError(error)) {
        throw const NetworkActivityLogException();
      }
      throw const InvalidActivityLogResponseException();
    } on ActivityLogException {
      rethrow;
    } catch (_) {
      throw const InvalidActivityLogResponseException();
    }
  }

  List<ActivityEntry> _entriesFromResponse(dynamic data) {
    if (data is! Map || data['entries'] is! List) {
      throw const InvalidActivityLogResponseException();
    }

    return (data['entries'] as List<dynamic>)
        .map((entry) {
          if (entry is! Map ||
              !_isNonEmptyString(entry['id']) ||
              entry['type'] is! String ||
              entry['actor'] is! Map ||
              entry['createdAt'] is! String) {
            throw const InvalidActivityLogResponseException();
          }

          final actor = entry['actor'] as Map;
          final payload = entry['payload'];
          if (!_isNonEmptyString(actor['participantId']) ||
              !_isNonEmptyString(actor['username']) ||
              (payload != null && payload is! Map)) {
            throw const InvalidActivityLogResponseException();
          }

          return ActivityEntry(
            id: entry['id'] as String,
            type: _activityType(entry['type'] as String),
            actorParticipantId: actor['participantId'] as String,
            actorUsername: actor['username'] as String,
            payload: payload == null
                ? <String, dynamic>{}
                : Map<String, dynamic>.from(payload as Map),
            createdAt: DateTime.parse(entry['createdAt'] as String).toLocal(),
          );
        })
        .toList(growable: false);
  }

  bool _isNonEmptyString(dynamic value) =>
      value is String && value.trim().isNotEmpty;

  ActivityType _activityType(String type) => switch (type) {
    'task_created' => ActivityType.taskCreated,
    'availability_updated' => ActivityType.availabilityUpdated,
    'expense_created' => ActivityType.expenseCreated,
    'schedule_confirmed' => ActivityType.scheduleConfirmed,
    _ => ActivityType.unknown,
  };

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
