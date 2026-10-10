import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/http_tasks_repository.dart';
import '../../domain/tasks_repository.dart';
import 'tasks_context.dart';
import 'tasks_notifier.dart';
import 'tasks_state.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return HttpTasksRepository(dio: ref.watch(dioClientProvider));
});

final tasksNotifierProvider = StateNotifierProvider.autoDispose
    .family<TasksNotifier, TasksState, TasksContext>((ref, tasksContext) {
      return TasksNotifier(
        repository: ref.watch(tasksRepositoryProvider),
        eventId: tasksContext.eventId,
        currentParticipantId: tasksContext.currentParticipantId,
        isOrganizer: tasksContext.isOrganizer,
        participants: tasksContext.participants,
      );
    });
