abstract interface class NotificationsRepository {
  Future<void> registerDevice(String pushToken);

  Future<void> unregisterDevice(String pushToken);
}
