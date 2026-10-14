import 'task.dart';

abstract class TasksRepository {
  Future<List<Task>> listTasks(String eventId);
  Future<Task> createTask(String eventId, String title);
  Future<Task> claimTask(String taskId);
  Future<Task> assignTask(String taskId, String participantId);
  Future<Task> completeTask(String taskId);
}
