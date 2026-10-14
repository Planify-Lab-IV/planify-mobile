import 'task.dart';
import 'task_status.dart';

// Acción única que puede ofrecerse para una tarea y una persona concretas.
enum TaskAction { claim, complete, reassign }

TaskAction? availableTaskAction({
  required Task task,
  required String? currentParticipantId,
  required bool isOrganizer,
}) {
  if (currentParticipantId == null || currentParticipantId.trim().isEmpty) {
    return null;
  }

  return switch (task.status) {
    TaskStatus.unassigned => TaskAction.claim,
    TaskStatus.pending
        when task.assignedToParticipantId == currentParticipantId =>
      TaskAction.complete,
    TaskStatus.pending when isOrganizer => TaskAction.reassign,
    TaskStatus.pending || TaskStatus.completed => null,
  };
}
