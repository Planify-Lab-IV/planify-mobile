import 'task.dart';

abstract class TasksRepository {
  Future<List<Task>> listTasks(String eventId);
  Future<Task> createTask(String eventId, String title);
  Future<void> claimTask(String taskId);
  Future<void> assignTask(String taskId, String participantId);
  Future<void> completeTask(String taskId);
}
