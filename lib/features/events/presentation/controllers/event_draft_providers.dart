import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/fake_events_repository.dart';
import '../../domain/event_draft.dart';
import '../../domain/events_repository.dart';
import 'create_event_notifier.dart';
import 'event_creation_state.dart';
import 'event_draft_notifier.dart';

final eventDraftProvider =
    StateNotifierProvider<EventDraftNotifier, EventDraft>((ref) {
      return EventDraftNotifier();
    });

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return FakeEventsRepository();
});

final createEventNotifierProvider =
    StateNotifierProvider<CreateEventNotifier, EventCreationState>((ref) {
      final repository = ref.watch(eventsRepositoryProvider);
      return CreateEventNotifier(repository);
    });
