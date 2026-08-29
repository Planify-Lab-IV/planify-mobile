import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dio_client.dart';
import '../../data/secure_storage.dart';
import '../services/deep_link_service.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return FlutterSecureStorageImpl();
});

final dioClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient.create(storage: storage);
});

final appLinksProvider = Provider<AppLinks>((ref) {
  return AppLinks();
});

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final appLinks = ref.watch(appLinksProvider);
  final service = DeepLinkService(appLinks: appLinks);
  ref.onDispose(() => service.dispose());
  return service;
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
