import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../data/fake_events_repository.dart';
import '../../domain/events_repository.dart';
import 'event_detail_notifier.dart';
import 'event_detail_state.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  // Punto de extensión: en PLANIFY-41 se puede reemplazar por HttpEventsRepository(dio: ref.watch(dioClientProvider))
  return FakeEventsRepository();
});

/*
  un provider sin .family es un singleton, solo existe una instancia en toda la app
  al agregarle el .family el provider se transforma en un factory indexado, como
  un Map<Parametro, Provider>, en este caso, se crearia un provider por event id
 */
final eventDetailNotifierProvider = StateNotifierProvider.autoDispose
    // le paso el provider, el estado que observa/maneja y el parametro
    .family<EventDetailNotifier, EventDetailState, String>((ref, eventId) {
      final repository = ref.watch(eventsRepositoryProvider);
      final authState = ref.watch(authNotifierProvider);
      final session = authState is AuthAuthenticated ? authState.session : null;

      return EventDetailNotifier(
        repository: repository,
        currentSession: session,
        eventId: eventId,
      );
    });
