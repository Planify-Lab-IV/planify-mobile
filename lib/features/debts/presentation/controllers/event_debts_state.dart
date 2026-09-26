import '../../domain/event_debts.dart';

enum EventDebtsLoadStatus { loading, success, error }

class EventDebtsState {
  final EventDebts eventDebts;
  final EventDebtsLoadStatus loadStatus;

  const EventDebtsState({
    this.eventDebts = const EventDebts(debts: [], allSettled: false),
    this.loadStatus = EventDebtsLoadStatus.loading,
  });

  bool get isLoading => loadStatus == EventDebtsLoadStatus.loading;
  bool get isSuccess => loadStatus == EventDebtsLoadStatus.success;
  bool get hasLoadError => loadStatus == EventDebtsLoadStatus.error;

  EventDebtsState copyWith({
    EventDebts? eventDebts,
    EventDebtsLoadStatus? loadStatus,
  }) {
    return EventDebtsState(
      eventDebts: eventDebts ?? this.eventDebts,
      loadStatus: loadStatus ?? this.loadStatus,
    );
  }
}
