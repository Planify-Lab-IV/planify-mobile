import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../domain/events_repository.dart';
import 'http_events_repository.dart';

// Repositorio de eventos compartido por creación, detalle y asistencia.
final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return HttpEventsRepository(dio: ref.watch(dioClientProvider));
});
