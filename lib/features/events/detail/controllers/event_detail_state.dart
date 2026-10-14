import '../../domain/event.dart';

enum EventDetailLoadStatus { initial, loading, success, notFound, error }

enum EventCancellationStatus { idle, inProgress, success, failure }

enum EventExpensesClosureStatus { idle, inProgress, success, failure }

class EventDetailState {
  final Event? event;
  final EventDetailLoadStatus loadStatus;
  final EventCancellationStatus cancellationStatus;
  final EventExpensesClosureStatus expensesClosureStatus;

  const EventDetailState({
    this.event,
    this.loadStatus = EventDetailLoadStatus.initial,
    this.cancellationStatus = EventCancellationStatus.idle,
    this.expensesClosureStatus = EventExpensesClosureStatus.idle,
  });

  const EventDetailState.initial()
    : this(
        loadStatus: EventDetailLoadStatus.initial,
        cancellationStatus: EventCancellationStatus.idle,
        expensesClosureStatus: EventExpensesClosureStatus.idle,
      );

  bool get isLoading => loadStatus == EventDetailLoadStatus.loading;
  bool get isSuccess => loadStatus == EventDetailLoadStatus.success;
  bool get isNotFound => loadStatus == EventDetailLoadStatus.notFound;
  bool get hasLoadError => loadStatus == EventDetailLoadStatus.error;

  bool get isCancelling =>
      cancellationStatus == EventCancellationStatus.inProgress;
  bool get cancellationSucceeded =>
      cancellationStatus == EventCancellationStatus.success;
  bool get cancellationFailed =>
      cancellationStatus == EventCancellationStatus.failure;

  bool get isClosingExpenses =>
      expensesClosureStatus == EventExpensesClosureStatus.inProgress;
  bool get expensesClosureSucceeded =>
      expensesClosureStatus == EventExpensesClosureStatus.success;
  bool get expensesClosureFailed =>
      expensesClosureStatus == EventExpensesClosureStatus.failure;

  EventDetailState copyWith({
    Event? event,
    EventDetailLoadStatus? loadStatus,
    EventCancellationStatus? cancellationStatus,
    EventExpensesClosureStatus? expensesClosureStatus,
  }) {
    return EventDetailState(
      event: event ?? this.event,
      loadStatus: loadStatus ?? this.loadStatus,
      cancellationStatus: cancellationStatus ?? this.cancellationStatus,
      expensesClosureStatus:
          expensesClosureStatus ?? this.expensesClosureStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventDetailState &&
          runtimeType == other.runtimeType &&
          event == other.event &&
          loadStatus == other.loadStatus &&
          cancellationStatus == other.cancellationStatus &&
          expensesClosureStatus == other.expensesClosureStatus;

  @override
  int get hashCode =>
      event.hashCode ^
      loadStatus.hashCode ^
      cancellationStatus.hashCode ^
      expensesClosureStatus.hashCode;

  @override
  String toString() {
    return 'EventDetailState(event: $event, loadStatus: $loadStatus, cancellationStatus: $cancellationStatus, expensesClosureStatus: $expensesClosureStatus)';
  }
}
