import 'dart:async';

import 'package:planify/core/services/push_messaging_service.dart';

class FakePushMessagingService implements PushMessagingService {
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();
  final StreamController<PushMessage> _foregroundMessageController =
      StreamController<PushMessage>.broadcast();
  final StreamController<PushMessage> _messageOpenedController =
      StreamController<PushMessage>.broadcast();

  bool permissionGranted;
  String? token;
  PushMessage? initialMessage;
  int requestPermissionCalls = 0;
  int getTokenCalls = 0;
  int getInitialMessageCalls = 0;

  FakePushMessagingService({
    this.permissionGranted = true,
    this.token = 'fake-push-token',
    this.initialMessage,
  });

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return permissionGranted;
  }

  @override
  Future<String?> getToken() async {
    getTokenCalls++;
    return token;
  }

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Stream<PushMessage> get onForegroundMessage =>
      _foregroundMessageController.stream;

  @override
  Stream<PushMessage> get onMessageOpened => _messageOpenedController.stream;

  @override
  Future<PushMessage?> getInitialMessage() async {
    getInitialMessageCalls++;
    return initialMessage;
  }

  void emitTokenRefresh(String newToken) {
    _tokenRefreshController.add(newToken);
  }

  void emitForegroundMessage(PushMessage message) {
    _foregroundMessageController.add(message);
  }

  void emitMessageOpened(PushMessage message) {
    _messageOpenedController.add(message);
  }

  Future<void> dispose() async {
    await _tokenRefreshController.close();
    await _foregroundMessageController.close();
    await _messageOpenedController.close();
  }
}
