import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/tasks/domain/task.dart';
import 'package:planify/features/tasks/domain/task_action.dart';
import 'package:planify/features/tasks/domain/task_status.dart';

void main() {
  Task task({required TaskStatus status, String? assignedToParticipantId}) {
    return Task(
      id: 'task-1',
      eventId: 'event-1',
      title: 'Comprar hielo',
      status: status,
      assignedToParticipantId: assignedToParticipantId,
      createdByParticipantId: 'participant-creator',
    );
  }

  TaskAction? actionFor(
    Task task, {
    String? currentParticipantId = 'participant-lucia',
    bool isOrganizer = false,
  }) {
    return availableTaskAction(
      task: task,
      currentParticipantId: currentParticipantId,
      isOrganizer: isOrganizer,
    );
  }

  group('availableTaskAction', () {
    test('ofrece tomar una tarea sin asignar a un participante', () {
      expect(actionFor(task(status: TaskStatus.unassigned)), TaskAction.claim);
    });

    test('ofrece completar la tarea pendiente asignada a mí', () {
      expect(
        actionFor(
          task(
            status: TaskStatus.pending,
            assignedToParticipantId: 'participant-lucia',
          ),
        ),
        TaskAction.complete,
      );
    });

    test('solo ofrece reasignar al organizador ante una tarea ajena', () {
      final pendingForAnotherPerson = task(
        status: TaskStatus.pending,
        assignedToParticipantId: 'participant-juan',
      );

      expect(actionFor(pendingForAnotherPerson), isNull);
      expect(
        actionFor(pendingForAnotherPerson, isOrganizer: true),
        TaskAction.reassign,
      );
    });

    test('no ofrece acción sobre una tarea completada', () {
      expect(actionFor(task(status: TaskStatus.completed)), isNull);
    });

    test(
      'no ofrece acciones si no se puede resolver al participante actual',
      () {
        expect(
          actionFor(
            task(status: TaskStatus.unassigned),
            currentParticipantId: null,
          ),
          isNull,
        );
      },
    );
  });
}
