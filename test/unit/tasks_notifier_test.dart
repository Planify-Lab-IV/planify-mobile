import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/domain/event_participant.dart';
import 'package:planify/features/tasks/data/fake_tasks_repository.dart';
import 'package:planify/features/tasks/domain/task.dart';
import 'package:planify/features/tasks/domain/task_status.dart';
import 'package:planify/features/tasks/presentation/controllers/tasks_notifier.dart';

void main() {
  const eventId = 'event-1';
  const luciaId = 'participant-lucia';
  const juanId = 'participant-juan';
  const lucia = EventParticipant(
    id: luciaId,
    eventId: eventId,
    userId: 'user-lucia',
    username: 'Lucía',
    isAnonymous: false,
    isOrganizer: true,
  );
  const juan = EventParticipant(
    id: juanId,
    eventId: eventId,
    userId: null,
    username: 'Juan',
    isAnonymous: true,
    isOrganizer: false,
  );

  Task pendingTask({String assignedTo = juanId}) {
    return Task(
      id: 'task-1',
      eventId: eventId,
      title: 'Comprar hielo',
      status: TaskStatus.pending,
      assignedToParticipantId: assignedTo,
      createdByParticipantId: luciaId,
    );
  }

  TasksNotifier notifier({
    required String? currentParticipantId,
    required bool isOrganizer,
    List<Task> tasks = const [],
  }) {
    return TasksNotifier(
      repository: FakeTasksRepository(
        delay: Duration.zero,
        initialTasks: tasks,
        currentParticipantIdForEvent: (_) => currentParticipantId,
      ),
      eventId: eventId,
      currentParticipantId: currentParticipantId,
      isOrganizer: isOrganizer,
      participants: const [lucia, juan],
    );
  }

  group('TasksNotifier', () {
    test('crea una tarea y la incorpora al estado', () async {
      final tasksNotifier = notifier(
        currentParticipantId: lucia.id,
        isOrganizer: true,
      );
      await Future<void>.delayed(Duration.zero);

      final created = await tasksNotifier.create('Comprar carbón');

      expect(created, isTrue);
      expect(tasksNotifier.state.tasks.single.title, 'Comprar carbón');
      expect(tasksNotifier.state.tasks.single.status, TaskStatus.unassigned);
    });

    test('no permite tomar una tarea si no hay participante actual', () async {
      const unassignedTask = Task(
        id: 'task-1',
        eventId: eventId,
        title: 'Comprar hielo',
        status: TaskStatus.unassigned,
        assignedToParticipantId: null,
        createdByParticipantId: luciaId,
      );
      final tasksNotifier = notifier(
        currentParticipantId: null,
        isOrganizer: false,
        tasks: [unassignedTask],
      );
      await Future<void>.delayed(Duration.zero);

      expect(await tasksNotifier.claim(unassignedTask.id), isFalse);
      expect(tasksNotifier.state.tasks.single.status, TaskStatus.unassigned);
    });

    test(
      'solo completa una tarea pendiente asignada al participante actual',
      () async {
        final tasksNotifier = notifier(
          currentParticipantId: lucia.id,
          isOrganizer: true,
          tasks: [pendingTask(assignedTo: lucia.id)],
        );
        await Future<void>.delayed(Duration.zero);

        expect(await tasksNotifier.complete('task-1'), isTrue);
        expect(tasksNotifier.state.tasks.single.status, TaskStatus.completed);
      },
    );

    test('bloquea completar una tarea pendiente de otra persona', () async {
      final tasksNotifier = notifier(
        currentParticipantId: lucia.id,
        isOrganizer: false,
        tasks: [pendingTask()],
      );
      await Future<void>.delayed(Duration.zero);

      expect(await tasksNotifier.complete('task-1'), isFalse);
      expect(tasksNotifier.state.tasks.single.status, TaskStatus.pending);
    });

    test(
      'permite reasignar al organizador solo a participantes del evento',
      () async {
        final tasksNotifier = notifier(
          currentParticipantId: lucia.id,
          isOrganizer: true,
          tasks: [pendingTask()],
        );
        await Future<void>.delayed(Duration.zero);

        expect(await tasksNotifier.assign('task-1', lucia.id), isTrue);
        expect(
          tasksNotifier.state.tasks.single.assignedToParticipantId,
          lucia.id,
        );
        expect(
          await tasksNotifier.assign('task-1', 'participant-unknown'),
          isFalse,
        );
      },
    );
  });
}
