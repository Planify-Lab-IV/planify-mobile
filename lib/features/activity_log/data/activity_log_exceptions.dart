sealed class ActivityLogException implements Exception {
  const ActivityLogException();
}

class NetworkActivityLogException extends ActivityLogException {
  const NetworkActivityLogException();
}

class InvalidActivityLogResponseException extends ActivityLogException {
  const InvalidActivityLogResponseException();
}
