import '../../domain/event.dart';

enum EventDetailLoadStatus { initial, loading, success, error }

enum EventCancellationStatus { idle, inProgress, success, failure }

class EventDetailState {
  final Event? event;
  final EventDetailLoadStatus loadStatus;
  final EventCancellationStatus cancellationStatus;

  const EventDetailState({
    this.event,
    this.loadStatus = EventDetailLoadStatus.initial,
    this.cancellationStatus = EventCancellationStatus.idle,
  });

  const EventDetailState.initial()
      : this(
          loadStatus: EventDetailLoadStatus.initial,
          cancellationStatus: EventCancellationStatus.idle,
        );

  bool get isLoading => loadStatus == EventDetailLoadStatus.loading;
  bool get isSuccess => loadStatus == EventDetailLoadStatus.success;
  bool get hasLoadError => loadStatus == EventDetailLoadStatus.error;

  bool get isCancelling =>
      cancellationStatus == EventCancellationStatus.inProgress;
  bool get cancellationSucceeded =>
      cancellationStatus == EventCancellationStatus.success;
  bool get cancellationFailed =>
      cancellationStatus == EventCancellationStatus.failure;

  EventDetailState copyWith({
    Event? event,
    EventDetailLoadStatus? loadStatus,
    EventCancellationStatus? cancellationStatus,
  }) {
    return EventDetailState(
      event: event ?? this.event,
      loadStatus: loadStatus ?? this.loadStatus,
      cancellationStatus: cancellationStatus ?? this.cancellationStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventDetailState &&
          runtimeType == other.runtimeType &&
          event == other.event &&
          loadStatus == other.loadStatus &&
          cancellationStatus == other.cancellationStatus;

  @override
  int get hashCode =>
      event.hashCode ^ loadStatus.hashCode ^ cancellationStatus.hashCode;

  @override
  String toString() {
    return 'EventDetailState(event: $event, loadStatus: $loadStatus, cancellationStatus: $cancellationStatus)';
  }
}
