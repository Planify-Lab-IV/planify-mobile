import '../domain/notifications_repository.dart';
import 'notification_exceptions.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  final Duration delay;
  final bool shouldThrowError;
  final List<String> registeredPushTokens = [];
  final List<String> unregisteredPushTokens = [];

  FakeNotificationsRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
  });

  @override
  Future<void> registerDevice(String pushToken, {String? sessionToken}) async {
    final normalizedPushToken = _normalizedRequiredValue(pushToken);
    await _waitOrThrow();
    registeredPushTokens.add(normalizedPushToken);
  }

  @override
  Future<void> unregisterDevice(
    String pushToken, {
    String? sessionToken,
  }) async {
    final normalizedPushToken = _normalizedRequiredValue(pushToken);
    await _waitOrThrow();
    unregisteredPushTokens.add(normalizedPushToken);
  }

  Future<void> _waitOrThrow() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldThrowError) {
      throw const NotificationOperationException();
    }
  }

  String _normalizedRequiredValue(String value) {
    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) {
      throw const NotificationValidationException();
    }
    return normalizedValue;
  }
}
