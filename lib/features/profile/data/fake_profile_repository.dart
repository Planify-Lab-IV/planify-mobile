import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';

// Implementación temporal en memoria hasta que la integración conecte el
// provider con el repositorio HTTP
class FakeProfileRepository implements ProfileRepository {
  final Duration delay;
  bool shouldThrowError;
  UserProfile _profile;

  FakeProfileRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
    UserProfile? initialProfile,
  }) : _profile = initialProfile ?? _defaultProfile;

  @override
  Future<UserProfile> getMyProfile() async {
    await _waitOrThrow();
    return _profile;
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? avatarFilePath,
  }) async {
    await _waitOrThrow();

    _profile = _profile.copyWith(name: name, avatarUrl: avatarFilePath);
    return _profile;
  }

  Future<void> _waitOrThrow() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldThrowError) {
      throw Exception('Could not update profile');
    }
  }

  static const UserProfile _defaultProfile = UserProfile(
    name: 'Juan Pérez',
    username: 'juan.perez',
    email: 'juan.perez@planify.com',
  );
}
