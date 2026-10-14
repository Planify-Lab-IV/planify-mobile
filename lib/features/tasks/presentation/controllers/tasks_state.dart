import 'package:flutter/foundation.dart';

import '../../domain/task.dart';

enum TasksLoadStatus { initial, loading, success, error }

enum TasksOperationStatus { idle, inProgress, success, error }

class TasksState {
  final List<Task> tasks;
  final TasksLoadStatus loadStatus;
  final TasksOperationStatus operationStatus;
  final String? activeTaskId;

  TasksState({
    List<Task> tasks = const [],
    this.loadStatus = TasksLoadStatus.initial,
    this.operationStatus = TasksOperationStatus.idle,
    this.activeTaskId,
  }) : tasks = List.unmodifiable(tasks);

  bool get isLoading => loadStatus == TasksLoadStatus.loading;
  bool get hasLoadError => loadStatus == TasksLoadStatus.error;
  bool get isOperating => operationStatus == TasksOperationStatus.inProgress;

  TasksState copyWith({
    List<Task>? tasks,
    TasksLoadStatus? loadStatus,
    TasksOperationStatus? operationStatus,
    String? activeTaskId,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      loadStatus: loadStatus ?? this.loadStatus,
      operationStatus: operationStatus ?? this.operationStatus,
      activeTaskId: activeTaskId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TasksState &&
          runtimeType == other.runtimeType &&
          listEquals(tasks, other.tasks) &&
          loadStatus == other.loadStatus &&
          operationStatus == other.operationStatus &&
          activeTaskId == other.activeTaskId;

  @override
  int get hashCode =>
      Object.hashAll(tasks) ^
      loadStatus.hashCode ^
      operationStatus.hashCode ^
      activeTaskId.hashCode;
}
