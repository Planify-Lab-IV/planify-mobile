import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// Dio es una libreria que sirve para hacer peticiones HTTP (como axios)
class DioClient {
  DioClient._();

  static Dio create({String? bearerToken}) {
    // baseUrl es la url del backend
    final baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );

    // aca se especifica cuanto tiempo espera la app antes de cancelar la request
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    /*
     si a la peticion se le pasa un bearerToken, Dio automaticamente le agrega:
     Authorization: Bearer<token>
     */
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (bearerToken != null) {
            options.headers['Authorization'] = 'Bearer $bearerToken';
          }
          handler.next(options);
        },
      ),
    );

    // si corres la app en debug logea todo
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return dio;
  }
}
