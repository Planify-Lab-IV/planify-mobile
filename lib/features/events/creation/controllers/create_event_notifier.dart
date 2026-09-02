import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/event_draft.dart';
import '../../domain/events_repository.dart';
import 'event_creation_state.dart';

class CreateEventNotifier extends StateNotifier<EventCreationState> {
  final EventsRepository _repository;
  final String _organizerId;

  CreateEventNotifier(this._repository, this._organizerId)
    : super(const EventCreationInitial());

  Future<void> createEvent(EventDraft draft) async {
    state = const EventCreationLoading();
    try {
      final event = await _repository.createEvent(draft, _organizerId);
      state = EventCreationSuccess(event);
    } catch (e) {
      state = EventCreationError(e.toString());
    }
  }

  void resetState() {
    state = const EventCreationInitial();
  }
}
