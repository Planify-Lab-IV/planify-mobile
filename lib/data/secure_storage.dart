// Future es equivalente a una Promise en javascript
abstract class SecureStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
}

class FakeSecureStorage implements SecureStorage {
  // variable privada
  String? _fakeStorage;

  @override
  Future<void> saveToken(String token) async {
    // simula que tarda
    await Future.delayed(const Duration(milliseconds: 200));
    _fakeStorage = token;
  }

  @override
  Future<String?> getToken() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _fakeStorage;
  }

  @override
  Future<void> deleteToken() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fakeStorage = null;
  }
}
