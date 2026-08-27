import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/event_draft.dart';
import '../../domain/events_repository.dart';
import 'event_creation_state.dart';

class CreateEventNotifier extends StateNotifier<EventCreationState> {
  final EventsRepository _repository;

  CreateEventNotifier(this._repository) : super(const EventCreationInitial());

  Future<void> createEvent(EventDraft draft) async {
    state = const EventCreationLoading();
    try {
      final event = await _repository.createEvent(draft);
      state = EventCreationSuccess(event);
    } catch (e) {
      state = EventCreationError(e.toString());
    }
  }

  void resetState() {
    state = const EventCreationInitial();
  }
}
