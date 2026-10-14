import '../../domain/event_debts.dart';

enum EventDebtsLoadStatus { loading, success, error }

class EventDebtsState {
  final EventDebts eventDebts;
  final EventDebtsLoadStatus loadStatus;
  final bool isSettling;
  final bool isRefreshing;

  const EventDebtsState({
    this.eventDebts = const EventDebts(debts: [], allSettled: false),
    this.loadStatus = EventDebtsLoadStatus.loading,
    this.isSettling = false,
    this.isRefreshing = false,
  });

  bool get isLoading => loadStatus == EventDebtsLoadStatus.loading;
  bool get isSuccess => loadStatus == EventDebtsLoadStatus.success;
  bool get hasLoadError => loadStatus == EventDebtsLoadStatus.error;

  EventDebtsState copyWith({
    EventDebts? eventDebts,
    EventDebtsLoadStatus? loadStatus,
    bool? isSettling,
    bool? isRefreshing,
  }) {
    return EventDebtsState(
      eventDebts: eventDebts ?? this.eventDebts,
      loadStatus: loadStatus ?? this.loadStatus,
      isSettling: isSettling ?? this.isSettling,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}
