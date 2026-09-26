import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/debts_repository.dart';
import 'event_debts_state.dart';

class EventDebtsNotifier extends StateNotifier<EventDebtsState> {
  final DebtsRepository _repository;
  final String _eventId;

  EventDebtsNotifier({
    required DebtsRepository repository,
    required String eventId,
  }) : _repository = repository,
       _eventId = eventId,
       super(const EventDebtsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loadStatus: EventDebtsLoadStatus.loading);

    try {
      final eventDebts = await _repository.listEventDebts(_eventId);
      if (!mounted) return;
      state = state.copyWith(
        eventDebts: eventDebts,
        loadStatus: EventDebtsLoadStatus.success,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loadStatus: EventDebtsLoadStatus.error);
    }
  }

  Future<void> reload() => load();
}
