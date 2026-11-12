sealed class NotificationsException implements Exception {
  const NotificationsException();
}

class NotificationValidationException extends NotificationsException {
  const NotificationValidationException();
}

class NotificationAuthorizationException extends NotificationsException {
  const NotificationAuthorizationException();
}

class NotificationOperationException extends NotificationsException {
  const NotificationOperationException();
}

class NetworkNotificationException extends NotificationsException {
  const NetworkNotificationException();
}
