import '../../domain/slot.dart';

enum AvailabilityLoadStatus { loading, success, error }

enum AvailabilitySaveStatus { idle, saving, success, error }

class AvailabilityState {
  final Set<Slot> selectedSlots;
  final AvailabilityLoadStatus loadStatus;
  final AvailabilitySaveStatus saveStatus;

  AvailabilityState({
    Set<Slot> selectedSlots = const {},
    this.loadStatus = AvailabilityLoadStatus.loading,
    this.saveStatus = AvailabilitySaveStatus.idle,
  }) : selectedSlots = Set<Slot>.unmodifiable(selectedSlots);

  bool get isLoading => loadStatus == AvailabilityLoadStatus.loading;
  bool get hasLoadError => loadStatus == AvailabilityLoadStatus.error;
  bool get isSaving => saveStatus == AvailabilitySaveStatus.saving;
  bool get hasSaveError => saveStatus == AvailabilitySaveStatus.error;

  AvailabilityState copyWith({
    Set<Slot>? selectedSlots,
    AvailabilityLoadStatus? loadStatus,
    AvailabilitySaveStatus? saveStatus,
  }) {
    return AvailabilityState(
      selectedSlots: selectedSlots ?? this.selectedSlots,
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
    );
  }
}
