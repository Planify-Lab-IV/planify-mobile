import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dio_client.dart';
import '../../data/secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return FlutterSecureStorageImpl();
});

final dioClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient.create(storage: storage);
});

// maneja el idioma
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null);

  void setLocale(Locale? locale) {
    state = locale;
  }
}

final localeNotifierProvider = StateNotifierProvider<LocaleNotifier, Locale?>((
  ref,
) {
  return LocaleNotifier();
});
