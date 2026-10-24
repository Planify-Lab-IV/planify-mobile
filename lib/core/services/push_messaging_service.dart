import 'package:firebase_messaging/firebase_messaging.dart';

class PushMessage {
  final String title;
  final String body;
  final String eventId;

  const PushMessage({
    required this.title,
    required this.body,
    required this.eventId,
  });

  static PushMessage? fromPayload({
    required String? title,
    required String? body,
    required Object? eventId,
  }) {
    if (eventId is! String || eventId.trim().isEmpty) return null;

    return PushMessage(
      title: title ?? '',
      body: body ?? '',
      eventId: eventId.trim(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PushMessage &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          body == other.body &&
          eventId == other.eventId;

  @override
  int get hashCode => Object.hash(title, body, eventId);
}

abstract interface class PushMessagingService {
  Future<bool> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<PushMessage> get onForegroundMessage;

  Stream<PushMessage> get onMessageOpened;

  Future<PushMessage?> getInitialMessage();
}

class FirebasePushMessagingService implements PushMessagingService {
  final FirebaseMessaging _messaging;

  FirebasePushMessagingService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<String?> getToken() {
    // El backend actual recibe tokens FCM, no identificadores de instalación.
    // ignore: deprecated_member_use
    return _messaging.getToken();
  }

  @override
  Stream<String> get onTokenRefresh {
    // Mantiene sincronizado el token FCM almacenado por el backend.
    // ignore: deprecated_member_use
    return _messaging.onTokenRefresh;
  }

  @override
  Stream<PushMessage> get onForegroundMessage {
    return FirebaseMessaging.onMessage
        .map(_pushMessageFromRemoteMessage)
        .where((message) => message != null)
        .cast<PushMessage>();
  }

  @override
  Stream<PushMessage> get onMessageOpened {
    return FirebaseMessaging.onMessageOpenedApp
        .map(_pushMessageFromRemoteMessage)
        .where((message) => message != null)
        .cast<PushMessage>();
  }

  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) return null;
    return _pushMessageFromRemoteMessage(message);
  }

  PushMessage? _pushMessageFromRemoteMessage(RemoteMessage message) {
    return PushMessage.fromPayload(
      title: message.notification?.title,
      body: message.notification?.body,
      eventId: message.data['eventId'],
    );
  }
}
