import 'package:dio/dio.dart';

import '../domain/notifications_repository.dart';
import 'notification_exceptions.dart';

class HttpNotificationsRepository implements NotificationsRepository {
  final Dio dio;

  HttpNotificationsRepository({required this.dio});

  @override
  Future<void> registerDevice(String pushToken, {String? sessionToken}) {
    return _updateDevice(
      '/notifications/register-device',
      pushToken,
      sessionToken,
    );
  }

  @override
  Future<void> unregisterDevice(String pushToken, {String? sessionToken}) {
    return _updateDevice(
      '/notifications/unregister-device',
      pushToken,
      sessionToken,
    );
  }

  Future<void> _updateDevice(
    String path,
    String pushToken,
    String? sessionToken,
  ) async {
    final normalizedPushToken = _normalizedRequiredValue(pushToken);

    try {
      await dio.post<dynamic>(
        path,
        data: {'pushToken': normalizedPushToken},
        options: sessionToken == null
            ? null
            : Options(headers: {'Authorization': 'Bearer $sessionToken'}),
      );
    } on NotificationsException {
      rethrow;
    } on DioException catch (error) {
      _throwForDioError(error);
    } catch (_) {
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

  Never _throwForDioError(DioException error) {
    switch (error.response?.statusCode) {
      case 400:
        throw const NotificationValidationException();
      case 401:
      case 403:
        throw const NotificationAuthorizationException();
    }

    if (_isNetworkError(error)) {
      throw const NetworkNotificationException();
    }

    throw const NotificationOperationException();
  }

  bool _isNetworkError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }
}
