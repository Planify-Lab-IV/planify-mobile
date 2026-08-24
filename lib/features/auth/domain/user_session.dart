enum UserRole { organizer, attendee, admin }

class UserSession {
  final String userId;
  final String email;
  final String name;
  final UserRole role;
  final String token;

  const UserSession({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.token,
  });

  // esto es como el equals, y por las mismas razones que en java, lo esta overrideando
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||  // si apuntan al mismo espacio de memoria -> true
      other is UserSession &&    // si las propiedades de los objetos son iguales
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          email == other.email &&
          name == other.name &&
          role == other.role &&
          token == other.token;

  /*
  esta funcion la usa dart/flutter por detras para manipular, comparar y filtrar los datos
  que ya están en la memoria del teléfono de forma instantánea y fluida
   */
  @override
  int get hashCode =>
      userId.hashCode ^
      email.hashCode ^
      name.hashCode ^
      role.hashCode ^
      token.hashCode;

  @override
  String toString() {
    return 'UserSession(userId: $userId, email: $email, name: $name, role: $role)';
  }
}
