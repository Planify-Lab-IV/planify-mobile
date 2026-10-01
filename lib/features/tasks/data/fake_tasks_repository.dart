import '../domain/task.dart';
import '../domain/task_status.dart';
import '../domain/tasks_repository.dart';
import 'task_exceptions.dart';

// El backend real obtiene la identidad de quien hace una acción desde el
// token. Para reproducir esa regla sin HTTP, el fake consulta el participante
// actual del evento mediante el callback inyectado.
class FakeTasksRepository implements TasksRepository {
  final Duration delay;
  final bool shouldThrowError;
  final String? Function(String eventId) _currentParticipantIdForEvent;
  final Map<String, Task> _tasksById = {};
  int _taskSequence = 0;

  FakeTasksRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
    String? Function(String eventId)? currentParticipantIdForEvent,
    List<Task> initialTasks = const [],
  }) : _currentParticipantIdForEvent =
           currentParticipantIdForEvent ?? ((_) => null) {
    for (final task in initialTasks) {
      _tasksById[task.id] = task;
      _taskSequence++;
    }
  }

  @override
  Future<List<Task>> listTasks(String eventId) async {
    await _waitOrThrow();
    return _tasksById.values
        .where((task) => task.eventId == eventId)
        .toList(growable: false);
  }

  @override
  Future<Task> createTask(String eventId, String title) async {
    await _waitOrThrow();
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) throw const TaskValidationException();

    final participantId = _requiredCurrentParticipantId(eventId);
    do {
      _taskSequence++;
    } while (_tasksById.containsKey('task-$_taskSequence'));
    final task = Task(
      id: 'task-$_taskSequence',
      eventId: eventId,
      title: normalizedTitle,
      status: TaskStatus.unassigned,
      assignedToParticipantId: null,
      createdByParticipantId: participantId,
    );
    _tasksById[task.id] = task;
    return task;
  }

  @override
  Future<void> claimTask(String taskId) async {
    await _waitOrThrow();
    final task = _taskById(taskId);
    if (task.status != TaskStatus.unassigned) {
      throw const TaskOperationException();
    }

    final participantId = _requiredCurrentParticipantId(task.eventId);
    _tasksById[task.id] = task.copyWith(
      status: TaskStatus.pending,
      assignedToParticipantId: participantId,
    );
  }

  @override
  Future<void> assignTask(String taskId, String participantId) async {
    await _waitOrThrow();
    final task = _taskById(taskId);
    if (task.status != TaskStatus.pending || participantId.trim().isEmpty) {
      throw const TaskValidationException();
    }

    _tasksById[task.id] = task.copyWith(assignedToParticipantId: participantId);
  }

  @override
  Future<void> completeTask(String taskId) async {
    await _waitOrThrow();
    final task = _taskById(taskId);
    final participantId = _requiredCurrentParticipantId(task.eventId);
    if (task.status != TaskStatus.pending ||
        task.assignedToParticipantId != participantId) {
      throw const TaskAuthorizationException();
    }

    _tasksById[task.id] = task.copyWith(status: TaskStatus.completed);
  }

  Future<void> _waitOrThrow() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldThrowError) throw const TaskOperationException();
  }

  Task _taskById(String taskId) {
    final task = _tasksById[taskId];
    if (task == null) throw const TaskNotFoundException();
    return task;
  }

  String _requiredCurrentParticipantId(String eventId) {
    final participantId = _currentParticipantIdForEvent(eventId);
    if (participantId == null || participantId.trim().isEmpty) {
      throw const TaskAuthorizationException();
    }
    return participantId;
  }
}
