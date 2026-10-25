import 'dart:async';

import '../../domain/notifications_repository.dart';

/// Conserva el orden de las operaciones para un mismo dispositivo entre sesiones.
class PushDeviceOperations {
  PushDeviceOperations(this._repository);

  final NotificationsRepository _repository;
  Future<void> _lastOperation = Future<void>.value();
  String? _lastPushToken;

  String? get lastPushToken => _lastPushToken;

  Future<void> register(String pushToken, String sessionToken) {
    _lastPushToken = pushToken;
    return _enqueue(
      () => _repository.registerDevice(pushToken, sessionToken: sessionToken),
    );
  }

  Future<void> unregister(String pushToken, String sessionToken) => _enqueue(
    () => _repository.unregisterDevice(pushToken, sessionToken: sessionToken),
  );

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = Completer<void>();
    _lastOperation = _lastOperation.then((_) async {
      try {
        await operation();
        result.complete();
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}
