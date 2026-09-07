import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fake_availability_repository.dart';
import '../../domain/availability_repository.dart';
import 'availability_notifier.dart';
import 'availability_state.dart';

final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  return FakeAvailabilityRepository();
});

final availabilityNotifierProvider = StateNotifierProvider.autoDispose
    .family<AvailabilityNotifier, AvailabilityState, String>((ref, eventId) {
      return AvailabilityNotifier(
        repository: ref.watch(availabilityRepositoryProvider),
        eventId: eventId,
      );
    });
