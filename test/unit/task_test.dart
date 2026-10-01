import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/tasks/domain/task.dart';
import 'package:planify/features/tasks/domain/task_status.dart';

void main() {
  const task = Task(
    id: 'task-1',
    eventId: 'event-1',
    title: 'Comprar hielo',
    status: TaskStatus.unassigned,
    assignedToParticipantId: null,
    createdByParticipantId: 'participant-lucia',
  );

  group('Task', () {
    test('conserva todos los datos del dominio', () {
      expect(task.id, 'task-1');
      expect(task.eventId, 'event-1');
      expect(task.title, 'Comprar hielo');
      expect(task.status, TaskStatus.unassigned);
      expect(task.assignedToParticipantId, isNull);
      expect(task.createdByParticipantId, 'participant-lucia');
    });

    test('copyWith crea una nueva versión sin modificar la original', () {
      final claimedTask = task.copyWith(
        status: TaskStatus.pending,
        assignedToParticipantId: 'participant-juan',
      );

      expect(claimedTask.status, TaskStatus.pending);
      expect(claimedTask.assignedToParticipantId, 'participant-juan');
      expect(claimedTask.title, task.title);
      expect(task.status, TaskStatus.unassigned);
      expect(task.assignedToParticipantId, isNull);
    });

    test('compara tareas por todos sus campos', () {
      const sameTask = Task(
        id: 'task-1',
        eventId: 'event-1',
        title: 'Comprar hielo',
        status: TaskStatus.unassigned,
        assignedToParticipantId: null,
        createdByParticipantId: 'participant-lucia',
      );
      final completedTask = task.copyWith(status: TaskStatus.completed);

      expect(task, sameTask);
      expect(task.hashCode, sameTask.hashCode);
      expect(task, isNot(completedTask));
    });

    test('toString incluye los campos útiles para diagnosticar', () {
      final description = task.toString();

      expect(description, contains('task-1'));
      expect(description, contains('Comprar hielo'));
      expect(description, contains('TaskStatus.unassigned'));
    });
  });

  test('TaskStatus define los tres estados del contrato', () {
    expect(TaskStatus.values, [
      TaskStatus.unassigned,
      TaskStatus.pending,
      TaskStatus.completed,
    ]);
  });
}
