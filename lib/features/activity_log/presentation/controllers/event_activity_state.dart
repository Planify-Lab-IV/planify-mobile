import '../../domain/activity_entry.dart';

enum EventActivityLoadStatus { loading, success, error }

class EventActivityState {
  final List<ActivityEntry> entries;
  final EventActivityLoadStatus loadStatus;

  const EventActivityState({
    this.entries = const <ActivityEntry>[],
    this.loadStatus = EventActivityLoadStatus.loading,
  });

  bool get isLoading => loadStatus == EventActivityLoadStatus.loading;
  bool get isSuccess => loadStatus == EventActivityLoadStatus.success;
  bool get hasLoadError => loadStatus == EventActivityLoadStatus.error;

  EventActivityState copyWith({
    List<ActivityEntry>? entries,
    EventActivityLoadStatus? loadStatus,
  }) {
    return EventActivityState(
      entries: entries ?? this.entries,
      loadStatus: loadStatus ?? this.loadStatus,
    );
  }
}
