import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/event_draft.dart';

class EventDraftNotifier extends StateNotifier<EventDraft> {
  EventDraftNotifier([EventDraft? initialDraft])
      : super(initialDraft ?? const EventDraft.empty());

  /// Actualiza los datos mínimos del Paso 1 (Información básica)
  void updateBasicInfo({
    required String name,
    required String location,
  }) {
    state = state.copyWith(
      name: name.trim(),
      location: location.trim(),
    );
  }

  /// Actualiza únicamente el nombre del evento
  void updateName(String name) {
    state = state.copyWith(name: name.trim());
  }

  /// Actualiza únicamente el lugar del evento
  void updateLocation(String location) {
    state = state.copyWith(location: location.trim());
  }

  /// Restablece el borrador a su estado vacío inicial
  void reset() {
    state = const EventDraft.empty();
  }
}
