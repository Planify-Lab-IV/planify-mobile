import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/http_activity_log_repository.dart';
import '../../domain/activity_log_repository.dart';
import 'event_activity_notifier.dart';
import 'event_activity_state.dart';

final activityLogRepositoryProvider = Provider<ActivityLogRepository>((ref) {
  return HttpActivityLogRepository(dio: ref.watch(dioClientProvider));
});

final eventActivityNotifierProvider = StateNotifierProvider.autoDispose
    .family<EventActivityNotifier, EventActivityState, String>((ref, eventId) {
      return EventActivityNotifier(
        repository: ref.watch(activityLogRepositoryProvider),
        eventId: eventId,
      );
    });
