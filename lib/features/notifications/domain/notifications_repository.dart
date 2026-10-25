abstract interface class NotificationsRepository {
  Future<void> registerDevice(String pushToken, {String? sessionToken});

  Future<void> unregisterDevice(String pushToken, {String? sessionToken});
}
