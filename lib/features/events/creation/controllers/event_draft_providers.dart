import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/http_events_repository.dart';
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
  return HttpEventsRepository(dio: ref.watch(dioClientProvider));
});

final createEventNotifierProvider =
    StateNotifierProvider<CreateEventNotifier, EventCreationState>((ref) {
      final repository = ref.watch(createEventsRepositoryProvider);
      return CreateEventNotifier(repository);
    });
