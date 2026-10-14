import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/tasks/data/fake_tasks_repository.dart';
import 'package:planify/features/tasks/data/task_exceptions.dart';
import 'package:planify/features/tasks/domain/task.dart';
import 'package:planify/features/tasks/domain/task_status.dart';

void main() {
  const eventId = 'event-1';
  var currentParticipantId = 'participant-lucia';

  FakeTasksRepository repository({List<Task> initialTasks = const []}) {
    return FakeTasksRepository(
      delay: Duration.zero,
      initialTasks: initialTasks,
      currentParticipantIdForEvent: (_) => currentParticipantId,
    );
  }

  group('FakeTasksRepository', () {
    setUp(() => currentParticipantId = 'participant-lucia');

    test('crea una tarea sin asignar y registra a su creador', () async {
      final fake = repository();
      final created = await fake.createTask(eventId, '  Comprar hielo  ');

      expect(created.id, 'task-1');
      expect(created.title, 'Comprar hielo');
      expect(created.status, TaskStatus.unassigned);
      expect(created.assignedToParticipantId, isNull);
      expect(created.createdByParticipantId, 'participant-lucia');
      expect(await fake.listTasks(eventId), [created]);
    });

    test('lista únicamente las tareas del evento pedido', () async {
      final taskForEvent = Task(
        id: 'task-1',
        eventId: eventId,
        title: 'Hielo',
        status: TaskStatus.unassigned,
        assignedToParticipantId: null,
        createdByParticipantId: currentParticipantId,
      );
      final otherTask = taskForEvent.copyWith(id: 'task-2', eventId: 'event-2');
      final tasks = await repository(
        initialTasks: [taskForEvent, otherTask],
      ).listTasks(eventId);

      expect(tasks, [taskForEvent]);
    });

    test(
      'tomar una tarea la deja pendiente y asignada al actor actual',
      () async {
        const task = Task(
          id: 'task-1',
          eventId: eventId,
          title: 'Hielo',
          status: TaskStatus.unassigned,
          assignedToParticipantId: null,
          createdByParticipantId: 'participant-ana',
        );
        final fake = repository(initialTasks: [task]);

        await fake.claimTask(task.id);
        final claimed = (await fake.listTasks(eventId)).single;

        expect(claimed.status, TaskStatus.pending);
        expect(claimed.assignedToParticipantId, currentParticipantId);
      },
    );

    test('solo quien la tiene asignada puede completarla', () async {
      const task = Task(
        id: 'task-1',
        eventId: eventId,
        title: 'Hielo',
        status: TaskStatus.pending,
        assignedToParticipantId: 'participant-juan',
        createdByParticipantId: 'participant-ana',
      );
      final fake = repository(initialTasks: [task]);

      await expectLater(
        fake.completeTask(task.id),
        throwsA(isA<TaskAuthorizationException>()),
      );

      currentParticipantId = 'participant-juan';
      await fake.completeTask(task.id);

      expect(
        (await fake.listTasks(eventId)).single.status,
        TaskStatus.completed,
      );
    });

    test(
      'reasignar conserva el estado pendiente y cambia el responsable',
      () async {
        const task = Task(
          id: 'task-1',
          eventId: eventId,
          title: 'Hielo',
          status: TaskStatus.pending,
          assignedToParticipantId: 'participant-juan',
          createdByParticipantId: 'participant-ana',
        );
        final fake = repository(initialTasks: [task]);

        await fake.assignTask(task.id, 'participant-lucia');
        final reassigned = (await fake.listTasks(eventId)).single;

        expect(reassigned.status, TaskStatus.pending);
        expect(reassigned.assignedToParticipantId, 'participant-lucia');
      },
    );
  });
}
