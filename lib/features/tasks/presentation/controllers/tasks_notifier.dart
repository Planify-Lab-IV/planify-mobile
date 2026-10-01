import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../events/domain/event_participant.dart';
import '../../domain/task.dart';
import '../../domain/task_action.dart';
import '../../domain/tasks_repository.dart';
import 'tasks_state.dart';

class TasksNotifier extends StateNotifier<TasksState> {
  final TasksRepository _repository;
  final String _eventId;
  final String? _currentParticipantId;
  final bool _isOrganizer;
  final List<EventParticipant> _participants;

  TasksNotifier({
    required TasksRepository repository,
    required String eventId,
    required String? currentParticipantId,
    required bool isOrganizer,
    required List<EventParticipant> participants,
  }) : this._(
         repository,
         eventId,
         currentParticipantId,
         isOrganizer,
         participants,
       );

  TasksNotifier._(
    this._repository,
    this._eventId,
    this._currentParticipantId,
    this._isOrganizer,
    List<EventParticipant> participants,
  ) : _participants = List.unmodifiable(participants),
      super(TasksState()) {
    load();
  }

  String? get currentParticipantId => _currentParticipantId;
  bool get isOrganizer => _isOrganizer;

  TaskAction? actionFor(Task task) {
    return availableTaskAction(
      task: task,
      currentParticipantId: _currentParticipantId,
      isOrganizer: _isOrganizer,
    );
  }

  Future<void> load() async {
    state = state.copyWith(loadStatus: TasksLoadStatus.loading);

    try {
      final tasks = await _repository.listTasks(_eventId);
      if (!mounted) return;
      state = state.copyWith(tasks: tasks, loadStatus: TasksLoadStatus.success);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loadStatus: TasksLoadStatus.error);
    }
  }

  Future<bool> create(String title) async {
    if (_currentParticipantId == null ||
        title.trim().isEmpty ||
        state.isOperating) {
      return false;
    }

    state = state.copyWith(operationStatus: TasksOperationStatus.inProgress);
    try {
      final task = await _repository.createTask(_eventId, title);
      if (!mounted) return false;
      state = state.copyWith(
        tasks: [...state.tasks, task],
        operationStatus: TasksOperationStatus.success,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(operationStatus: TasksOperationStatus.error);
      return false;
    }
  }

  Future<bool> claim(String taskId) {
    return _runTaskOperation(
      taskId: taskId,
      expectedAction: TaskAction.claim,
      operation: () => _repository.claimTask(taskId),
    );
  }

  Future<bool> assign(String taskId, String participantId) {
    if (!_participants.any((participant) => participant.id == participantId)) {
      return Future.value(false);
    }

    return _runTaskOperation(
      taskId: taskId,
      expectedAction: TaskAction.reassign,
      operation: () => _repository.assignTask(taskId, participantId),
    );
  }

  Future<bool> complete(String taskId) {
    return _runTaskOperation(
      taskId: taskId,
      expectedAction: TaskAction.complete,
      operation: () => _repository.completeTask(taskId),
    );
  }

  Future<bool> _runTaskOperation({
    required String taskId,
    required TaskAction expectedAction,
    required Future<void> Function() operation,
  }) async {
    if (state.isOperating) return false;

    final task = _taskById(taskId);
    if (task == null || actionFor(task) != expectedAction) return false;

    state = state.copyWith(
      operationStatus: TasksOperationStatus.inProgress,
      activeTaskId: taskId,
    );
    try {
      await operation();
      final tasks = await _repository.listTasks(_eventId);
      if (!mounted) return false;
      state = state.copyWith(
        tasks: tasks,
        operationStatus: TasksOperationStatus.success,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(operationStatus: TasksOperationStatus.error);
      return false;
    }
  }

  Task? _taskById(String taskId) {
    for (final task in state.tasks) {
      if (task.id == taskId) return task;
    }
    return null;
  }
}
