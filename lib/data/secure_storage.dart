import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Future es equivalente a una Promise en javascript
abstract class SecureStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
}

class FlutterSecureStorageImpl implements SecureStorage {
  // FlutterSecureStorage es una libreria para guardar tokens de forma cifrada en la memoria del celular
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'auth_bearer_token';

  FlutterSecureStorageImpl({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  @override
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}

class FakeSecureStorage implements SecureStorage {
  final Duration delay;
  String? _fakeStorage;

  FakeSecureStorage({this.delay = const Duration(milliseconds: 200)});

  @override
  Future<void> saveToken(String token) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    _fakeStorage = token;
  }

  @override
  Future<String?> getToken() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return _fakeStorage;
  }

  @override
  Future<void> deleteToken() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    _fakeStorage = null;
  }
}
