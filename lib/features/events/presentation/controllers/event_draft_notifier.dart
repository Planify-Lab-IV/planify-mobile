import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/event_draft.dart';

class EventDraftNotifier extends StateNotifier<EventDraft> {
  // 1. los corchetes muestran que el parametro es opcional vs el signo de pregunta
  //    indica que puede ser null
  // 2. lo que esta haciendo aca es inicializando el EventDraftNotifier con un estado
  //    inicial, que puede ser el Empty Draft (normalmente) o un Draft anterior
  EventDraftNotifier([super.initialDraft = const EventDraft.empty()]);

  // actualiza los datos del paso 1
  void updateBasicInfo({required String name, required String location}) {
    state = state.copyWith(name: name.trim(), location: location.trim());
  }

  // actualiza el nombre del evento
  void updateName(String name) {
    state = state.copyWith(name: name.trim());
  }

  // actualiza el lugar del evento
  void updateLocation(String location) {
    state = state.copyWith(location: location.trim());
  }

  void reset() {
    state = const EventDraft.empty();
  }
}
