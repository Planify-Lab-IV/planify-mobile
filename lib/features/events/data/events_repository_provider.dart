import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/events_repository.dart';
import 'fake_events_repository.dart';

/// Repositorio temporal en memoria para probar el flujo de eventos sin backend.
///
/// Es un provider único para que creación, detalle y asistencia compartan los
/// mismos eventos durante una ejecución de la app.
final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return FakeEventsRepository();
});
