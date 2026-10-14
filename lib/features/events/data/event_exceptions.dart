sealed class EventsException implements Exception {
  const EventsException();
}

class EventNotFoundException extends EventsException {
  const EventNotFoundException();
}

class EventCancellationException extends EventsException {
  const EventCancellationException();
}

class EventScheduleValidationException extends EventsException {
  const EventScheduleValidationException();
}

class EventScheduleAuthorizationException extends EventsException {
  const EventScheduleAuthorizationException();
}

class EventScheduleConfirmationException extends EventsException {
  const EventScheduleConfirmationException();
}

class AttendanceResponseException extends EventsException {
  const AttendanceResponseException();
}

class NetworkEventException extends EventsException {
  const NetworkEventException();
}

class InvalidEventResponseException extends EventsException {
  const InvalidEventResponseException();
}

class UnsupportedEventOperationException extends EventsException {
  const UnsupportedEventOperationException();
}
