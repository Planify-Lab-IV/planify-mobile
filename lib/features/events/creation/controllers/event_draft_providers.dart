import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/events_repository_provider.dart';
import '../../domain/events_repository.dart';
import '../../domain/event_draft.dart';
import 'create_event_notifier.dart';
import 'event_creation_state.dart';
import 'event_draft_notifier.dart';

final eventDraftProvider =
    StateNotifierProvider<EventDraftNotifier, EventDraft>((ref) {
      return EventDraftNotifier();
    });

final createEventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return ref.watch(eventsRepositoryProvider);
});

final createEventNotifierProvider =
    StateNotifierProvider<CreateEventNotifier, EventCreationState>((ref) {
      final repository = ref.watch(createEventsRepositoryProvider);
      return CreateEventNotifier(repository);
    });
