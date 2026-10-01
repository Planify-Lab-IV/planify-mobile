import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fake_tasks_repository.dart';
import '../../domain/tasks_repository.dart';
import 'tasks_context.dart';
import 'tasks_notifier.dart';
import 'tasks_state.dart';

final tasksRepositoryProvider = Provider.family<TasksRepository, String?>((
  ref,
  currentParticipantId,
) {
  return FakeTasksRepository(
    currentParticipantIdForEvent: (_) => currentParticipantId,
  );
});

final tasksNotifierProvider = StateNotifierProvider.autoDispose
    .family<TasksNotifier, TasksState, TasksContext>((ref, tasksContext) {
      return TasksNotifier(
        repository: ref.watch(
          tasksRepositoryProvider(tasksContext.currentParticipantId),
        ),
        eventId: tasksContext.eventId,
        currentParticipantId: tasksContext.currentParticipantId,
        isOrganizer: tasksContext.isOrganizer,
        participants: tasksContext.participants,
      );
    });
