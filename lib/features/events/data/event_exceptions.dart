sealed class EventsException implements Exception {
  const EventsException();
}

class EventNotFoundException extends EventsException {
  const EventNotFoundException();
}

class EventCancellationException extends EventsException {
  const EventCancellationException();
}

class AttendanceResponseException extends EventsException {
  const AttendanceResponseException();
}

class NetworkEventException extends EventsException {
  const NetworkEventException();
}
