import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/http_activity_log_repository.dart';
import '../../domain/activity_log_repository.dart';
import '../../domain/unread_counts.dart';
import 'event_activity_notifier.dart';
import 'event_activity_state.dart';

final activityLogRepositoryProvider = Provider<ActivityLogRepository>((ref) {
  return HttpActivityLogRepository(dio: ref.watch(dioClientProvider));
});

final unreadCountsProvider = FutureProvider.autoDispose<UnreadCounts>((ref) {
  return ref.watch(activityLogRepositoryProvider).getUnreadCounts();
});

final eventActivityNotifierProvider = StateNotifierProvider.autoDispose
    .family<EventActivityNotifier, EventActivityState, String>((ref, eventId) {
      return EventActivityNotifier(
        repository: ref.watch(activityLogRepositoryProvider),
        eventId: eventId,
        onUnreadCountsChanged: () => ref.invalidate(unreadCountsProvider),
        onMarkStarted: () {
          final keepAliveLink = ref.keepAlive();
          return keepAliveLink.close;
        },
      );
    });
