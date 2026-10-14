// Datos editables y de solo lectura de la cuenta del organizador.
class UserProfile {
  final String name;
  final String username;
  final String email;
  final String? avatarUrl;

  const UserProfile({
    required this.name,
    required this.username,
    required this.email,
    this.avatarUrl,
  });

  UserProfile copyWith({
    String? name,
    String? username,
    String? email,
    String? avatarUrl,
  }) {
    return UserProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          username == other.username &&
          email == other.email &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode => Object.hash(name, username, email, avatarUrl);

  @override
  String toString() =>
      'UserProfile(name: $name, username: $username, email: $email, avatarUrl: $avatarUrl)';
}
