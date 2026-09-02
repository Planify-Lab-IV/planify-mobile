import '../../domain/event.dart';

enum EventDetailStatus { initial, loading, success, error }

class EventDetailState {
  final Event? event;
  final EventDetailStatus status;
  final bool isCancelling;
  final String? errorMessage;
  final bool cancellationSuccess;

  const EventDetailState({
    this.event,
    this.status = EventDetailStatus.initial,
    this.isCancelling = false,
    this.errorMessage,
    this.cancellationSuccess = false,
  });

  const EventDetailState.initial() : this(status: EventDetailStatus.initial);

  bool get isLoading => status == EventDetailStatus.loading;
  bool get isSuccess => status == EventDetailStatus.success;
  bool get hasError => status == EventDetailStatus.error;

  EventDetailState copyWith({
    Event? event,
    EventDetailStatus? status,
    bool? isCancelling,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? cancellationSuccess,
  }) {
    return EventDetailState(
      event: event ?? this.event,
      status: status ?? this.status,
      isCancelling: isCancelling ?? this.isCancelling,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      cancellationSuccess: cancellationSuccess ?? this.cancellationSuccess,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventDetailState &&
          runtimeType == other.runtimeType &&
          event == other.event &&
          status == other.status &&
          isCancelling == other.isCancelling &&
          errorMessage == other.errorMessage &&
          cancellationSuccess == other.cancellationSuccess;

  @override
  int get hashCode =>
      event.hashCode ^
      status.hashCode ^
      isCancelling.hashCode ^
      errorMessage.hashCode ^
      cancellationSuccess.hashCode;

  @override
  String toString() {
    return 'EventDetailState(event: $event, status: $status, isCancelling: $isCancelling, errorMessage: $errorMessage, cancellationSuccess: $cancellationSuccess)';
  }
}
