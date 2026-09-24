import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../events/detail/controllers/events_providers.dart';
import '../../data/fake_tasks_repository.dart';
import '../../domain/tasks_repository.dart';
import 'tasks_notifier.dart';
import 'tasks_state.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return FakeTasksRepository(
    currentParticipantIdForEvent: (eventId) {
      return ref
          .read(eventDetailNotifierProvider(eventId).notifier)
          .currentParticipantId;
    },
  );
});

final tasksNotifierProvider = StateNotifierProvider.autoDispose
    .family<TasksNotifier, TasksState, String>((ref, eventId) {
      final eventDetailState = ref.watch(eventDetailNotifierProvider(eventId));
      final eventDetailNotifier = ref.read(
        eventDetailNotifierProvider(eventId).notifier,
      );

      return TasksNotifier(
        repository: ref.watch(tasksRepositoryProvider),
        eventId: eventId,
        currentParticipantId: eventDetailNotifier.currentParticipantId,
        isOrganizer: eventDetailNotifier.isOrganizer,
        participants: eventDetailState.event?.participants ?? const [],
      );
    });
