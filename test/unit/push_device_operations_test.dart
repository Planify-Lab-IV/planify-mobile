import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/notifications/domain/notifications_repository.dart';
import 'package:planify/features/notifications/presentation/controllers/push_device_operations.dart';

class _Repository implements NotificationsRepository {
  final started = Completer<void>();
  final release = Completer<void>();
  final calls = <String>[];

  @override
  Future<void> registerDevice(String pushToken, {String? sessionToken}) async {
    calls.add('register:$sessionToken');
    if (sessionToken == 'session-a') {
      started.complete();
      await release.future;
    }
  }

  @override
  Future<void> unregisterDevice(
    String pushToken, {
    String? sessionToken,
  }) async {
    calls.add('unregister:$sessionToken');
  }
}

void main() {
  test(
    'serializa registro, desregistro y registro de la siguiente cuenta',
    () async {
      final repository = _Repository();
      final operations = PushDeviceOperations(repository);
      final first = operations.register('push-token', 'session-a');
      await repository.started.future;
      final logout = operations.unregister('push-token', 'session-a');
      final second = operations.register('push-token', 'session-b');
      await Future<void>.delayed(Duration.zero);
      expect(repository.calls, ['register:session-a']);
      repository.release.complete();
      await Future.wait([first, logout, second]);
      expect(repository.calls, [
        'register:session-a',
        'unregister:session-a',
        'register:session-b',
      ]);
    },
  );
}
