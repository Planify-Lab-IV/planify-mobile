import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class PushPermissionStore {
  Future<bool> wasRequested();
  Future<void> markRequested();
}

class PersistentPushPermissionStore implements PushPermissionStore {
  PersistentPushPermissionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'push_permission_requested';
  final FlutterSecureStorage _storage;

  @override
  Future<bool> wasRequested() async => await _storage.read(key: _key) == 'true';

  @override
  Future<void> markRequested() => _storage.write(key: _key, value: 'true');
}

class MemoryPushPermissionStore implements PushPermissionStore {
  bool requested = false;

  @override
  Future<bool> wasRequested() async => requested;

  @override
  Future<void> markRequested() async {
    requested = true;
  }
}
