import 'package:dio/dio.dart';

import '../domain/task.dart';
import '../domain/task_status.dart';
import '../domain/tasks_repository.dart';
import 'task_exceptions.dart';

class HttpTasksRepository implements TasksRepository {
  final Dio dio;

  HttpTasksRepository({required this.dio});

  @override
  Future<List<Task>> listTasks(String eventId) async {
    final normalizedEventId = _normalizedRequiredValue(eventId);

    try {
      final response = await dio.get<dynamic>(
        '/events/$normalizedEventId/tasks',
      );
      return _tasksFromResponse(response.data);
    } on TasksException {
      rethrow;
    } on DioException catch (error) {
      _throwForDioError(error);
    } catch (_) {
      throw const InvalidTaskResponseException();
    }
  }

  @override
  Future<Task> createTask(String eventId, String title) async {
    final normalizedEventId = _normalizedRequiredValue(eventId);
    final normalizedTitle = _normalizedRequiredValue(title);

    try {
      final response = await dio.post<dynamic>(
        '/events/$normalizedEventId/tasks',
        data: {'title': normalizedTitle},
      );
      return _taskFromResponse(response.data);
    } on TasksException {
      rethrow;
    } on DioException catch (error) {
      _throwForDioError(error);
    } catch (_) {
      throw const InvalidTaskResponseException();
    }
  }

  @override
  Future<Task> claimTask(String taskId) async {
    final normalizedTaskId = _normalizedRequiredValue(taskId);
    return _postTaskAction('/tasks/$normalizedTaskId/claim');
  }

  @override
  Future<Task> assignTask(String taskId, String participantId) async {
    final normalizedTaskId = _normalizedRequiredValue(taskId);
    final normalizedParticipantId = _normalizedRequiredValue(participantId);
    return _postTaskAction(
      '/tasks/$normalizedTaskId/assign',
      data: {'participantId': normalizedParticipantId},
    );
  }

  @override
  Future<Task> completeTask(String taskId) async {
    final normalizedTaskId = _normalizedRequiredValue(taskId);
    return _postTaskAction('/tasks/$normalizedTaskId/complete');
  }

  String _normalizedRequiredValue(String value) {
    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) {
      throw const TaskValidationException();
    }
    return normalizedValue;
  }

  List<Task> _tasksFromResponse(dynamic data) {
    if (data is! Map || data['tasks'] is! List) {
      throw const InvalidTaskResponseException();
    }

    return (data['tasks'] as List<dynamic>)
        .map(_taskFromResponse)
        .toList(growable: false);
  }

  Future<Task> _postTaskAction(String path, {Object? data}) async {
    try {
      final response = await dio.post<dynamic>(path, data: data);
      return _taskFromResponse(response.data);
    } on TasksException {
      rethrow;
    } on DioException catch (error) {
      _throwForDioError(error);
    } catch (_) {
      throw const InvalidTaskResponseException();
    }
  }

  Task _taskFromResponse(dynamic data) {
    if (data is! Map) throw const InvalidTaskResponseException();

    final assignedToParticipantId = data['assignedToParticipantId'];
    if (assignedToParticipantId != null &&
        (assignedToParticipantId is! String ||
            assignedToParticipantId.trim().isEmpty)) {
      throw const InvalidTaskResponseException();
    }

    return Task(
      id: _requiredString(data, 'id'),
      eventId: _requiredString(data, 'eventId'),
      title: _requiredString(data, 'title'),
      status: _taskStatus(data['status']),
      assignedToParticipantId: assignedToParticipantId as String?,
      createdByParticipantId: _requiredString(data, 'createdByParticipantId'),
    );
  }

  String _requiredString(Map<dynamic, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      throw const InvalidTaskResponseException();
    }
    return value;
  }

  TaskStatus _taskStatus(dynamic value) {
    return switch (value) {
      'unassigned' => TaskStatus.unassigned,
      'pending' => TaskStatus.pending,
      'completed' => TaskStatus.completed,
      _ => throw const InvalidTaskResponseException(),
    };
  }

  Never _throwForDioError(DioException error) {
    switch (error.response?.statusCode) {
      case 400:
        throw const TaskValidationException();
      case 401:
      case 403:
        throw const TaskAuthorizationException();
      case 404:
        throw const TaskNotFoundException();
    }

    if (_isNetworkError(error)) {
      throw const NetworkTaskException();
    }

    throw const TaskOperationException();
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
