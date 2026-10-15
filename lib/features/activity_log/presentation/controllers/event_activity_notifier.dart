import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/activity_log_repository.dart';
import 'event_activity_state.dart';

class EventActivityNotifier extends StateNotifier<EventActivityState> {
  final ActivityLogRepository repository;
  final String eventId;
  final void Function()? onUnreadCountsChanged;
  final void Function()? onLoadFinished;

  EventActivityNotifier({
    required this.repository,
    required this.eventId,
    this.onUnreadCountsChanged,
    this.onLoadFinished,
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
      onLoadFinished?.call();
      return;
    }

    // Reading activity is a secondary effect: its failure must not hide the feed.
    try {
      await repository.markEventAsRead(eventId);
      if (mounted) onUnreadCountsChanged?.call();
    } catch (_) {
    } finally {
      onLoadFinished?.call();
    }
  }

  Future<void> reload() => load();
}
