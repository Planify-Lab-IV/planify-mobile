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
    } on DioException {
      throw const TaskOperationException();
    } catch (_) {
      throw const TaskOperationException();
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
    } on DioException {
      throw const TaskOperationException();
    } catch (_) {
      throw const TaskOperationException();
    }
  }

  @override
  Future<void> claimTask(String taskId) {
    throw UnimplementedError('claimTask se implementa en el paso 2.');
  }

  @override
  Future<void> assignTask(String taskId, String participantId) {
    throw UnimplementedError('assignTask se implementa en el paso 2.');
  }

  @override
  Future<void> completeTask(String taskId) {
    throw UnimplementedError('completeTask se implementa en el paso 2.');
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
      throw const TaskOperationException();
    }

    return (data['tasks'] as List<dynamic>)
        .map(_taskFromResponse)
        .toList(growable: false);
  }

  Task _taskFromResponse(dynamic data) {
    if (data is! Map) throw const TaskOperationException();

    final assignedToParticipantId = data['assignedToParticipantId'];
    if (assignedToParticipantId != null &&
        (assignedToParticipantId is! String ||
            assignedToParticipantId.trim().isEmpty)) {
      throw const TaskOperationException();
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
      throw const TaskOperationException();
    }
    return value;
  }

  TaskStatus _taskStatus(dynamic value) {
    return switch (value) {
      'unassigned' => TaskStatus.unassigned,
      'pending' => TaskStatus.pending,
      'completed' => TaskStatus.completed,
      _ => throw const TaskOperationException(),
    };
  }
}
