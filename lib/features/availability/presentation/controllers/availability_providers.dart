import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/fake_availability_repository.dart';
import '../../data/http_availability_repository.dart';
import '../../domain/availability_repository.dart';
import 'availability_heatmap_notifier.dart';
import 'availability_heatmap_state.dart';
import 'availability_notifier.dart';
import 'availability_state.dart';

final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  return HttpAvailabilityRepository(dio: ref.watch(dioClientProvider));
});

final availabilityHeatmapRepositoryProvider = Provider<AvailabilityRepository>((
  ref,
) {
  return FakeAvailabilityRepository();
});

final availabilityNotifierProvider = StateNotifierProvider.autoDispose
    .family<AvailabilityNotifier, AvailabilityState, String>((ref, eventId) {
      return AvailabilityNotifier(
        repository: ref.watch(availabilityRepositoryProvider),
        eventId: eventId,
      );
    });

final availabilityHeatmapNotifierProvider = StateNotifierProvider.autoDispose
    .family<AvailabilityHeatmapNotifier, AvailabilityHeatmapState, String>((
      ref,
      eventId,
    ) {
      return AvailabilityHeatmapNotifier(
        repository: ref.watch(availabilityHeatmapRepositoryProvider),
        eventId: eventId,
      );
    });
