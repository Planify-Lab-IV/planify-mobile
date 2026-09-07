import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/availability_repository.dart';
import '../../domain/slot.dart';
import 'availability_state.dart';

class AvailabilityNotifier extends StateNotifier<AvailabilityState> {
  final AvailabilityRepository repository;
  final String eventId;

  AvailabilityNotifier({
    required this.repository,
    required this.eventId,
  }) : super(AvailabilityState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loadStatus: AvailabilityLoadStatus.loading);

    try {
      final slots = await repository.load(eventId);
      if (!mounted) return;
      state = state.copyWith(
        selectedSlots: slots.toSet(),
        loadStatus: AvailabilityLoadStatus.success,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loadStatus: AvailabilityLoadStatus.error);
    }
  }

  void toggleSlot(Slot slot) {
    final updatedSlots = Set<Slot>.from(state.selectedSlots);
    if (!updatedSlots.add(slot)) {
      updatedSlots.remove(slot);
    }
    state = state.copyWith(
      selectedSlots: updatedSlots,
      saveStatus: AvailabilitySaveStatus.idle,
    );
  }

  void markSlot(Slot slot) {
    if (state.selectedSlots.contains(slot)) return;

    state = state.copyWith(
      selectedSlots: {...state.selectedSlots, slot},
      saveStatus: AvailabilitySaveStatus.idle,
    );
  }

  Future<void> save() async {
    if (state.isSaving) return;

    state = state.copyWith(saveStatus: AvailabilitySaveStatus.saving);
    try {
      await repository.save(eventId, state.selectedSlots.toList());
      if (!mounted) return;
      state = state.copyWith(saveStatus: AvailabilitySaveStatus.success);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(saveStatus: AvailabilitySaveStatus.error);
    }
  }
}
