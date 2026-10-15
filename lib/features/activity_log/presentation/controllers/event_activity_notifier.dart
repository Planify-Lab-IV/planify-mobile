import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/activity_log_repository.dart';
import 'event_activity_state.dart';

typedef MarkOperationFinished = void Function();
typedef MarkOperationStarter = MarkOperationFinished? Function();

class EventActivityNotifier extends StateNotifier<EventActivityState> {
  final ActivityLogRepository repository;
  final String eventId;
  final void Function()? onUnreadCountsChanged;
  final MarkOperationStarter? onMarkStarted;

  EventActivityNotifier({
    required this.repository,
    required this.eventId,
    this.onUnreadCountsChanged,
    this.onMarkStarted,
  }) : super(const EventActivityState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loadStatus: EventActivityLoadStatus.loading);

    try {
      final entries = await repository.listEventActivity(eventId);
      if (!mounted) return;
      state = state.copyWith(
        entries: entries,
        loadStatus: EventActivityLoadStatus.success,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loadStatus: EventActivityLoadStatus.error);
      return;
    }

    final onMarkFinished = onMarkStarted?.call();
    try {
      await repository.markEventAsRead(eventId);
      if (mounted) onUnreadCountsChanged?.call();
    } catch (_) {
    } finally {
      onMarkFinished?.call();
    }
  }

  Future<void> reload() => load();
}
