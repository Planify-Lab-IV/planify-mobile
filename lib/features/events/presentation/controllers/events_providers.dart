import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/fake_events_repository.dart';
import '../../domain/events_repository.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  // Punto de extensión: en PLANIFY-41 se puede reemplazar por HttpEventsRepository(dio: ref.watch(dioClientProvider))
  return FakeEventsRepository();
});
