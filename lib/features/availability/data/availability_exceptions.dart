sealed class AvailabilityException implements Exception {
  const AvailabilityException();
}

class NetworkAvailabilityException extends AvailabilityException {
  const NetworkAvailabilityException();
}

class InvalidAvailabilityResponseException extends AvailabilityException {
  const InvalidAvailabilityResponseException();
}

class AvailabilitySaveException extends AvailabilityException {
  const AvailabilitySaveException();
}
