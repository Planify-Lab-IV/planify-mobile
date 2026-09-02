import '../../domain/event.dart';

sealed class EventCreationState {
  const EventCreationState();
}

class EventCreationInitial extends EventCreationState {
  const EventCreationInitial();
}

class EventCreationLoading extends EventCreationState {
  const EventCreationLoading();
}

class EventCreationSuccess extends EventCreationState {
  final Event event;
  const EventCreationSuccess(this.event);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventCreationSuccess &&
          runtimeType == other.runtimeType &&
          event == other.event;

  @override
  int get hashCode => event.hashCode;
}

class EventCreationError extends EventCreationState {
  final String message;
  const EventCreationError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventCreationError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
