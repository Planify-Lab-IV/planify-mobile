import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'secure_storage.dart';

// Dio es una libreria que sirve para hacer peticiones HTTP (como axios)
class DioClient {
  DioClient._();

  static Dio create({SecureStorage? storage, String? bearerToken}) {
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
        sendTimeout: const Duration(seconds: 10),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    /*
     si a la peticion se le pasa un bearerToken o storage, Dio automaticamente le agrega:
     Authorization: Bearer <token>
     */
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // esto se usa principalmente para tests, cuando queres pasar un token fijo
          if (bearerToken != null) {
            options.headers['Authorization'] = 'Bearer $bearerToken';
          }
          // esto se usa cuando la app corre realmente
          else if (storage != null) {
            final token = await storage.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
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
