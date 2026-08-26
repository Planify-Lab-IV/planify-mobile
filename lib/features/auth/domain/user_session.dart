enum UserRole { organizer, attendee, admin, anonymous }

sealed class UserSession {
  final String userId;
  final String name;
  final UserRole role;
  final String token;

  const UserSession({
    required this.userId,
    required this.name,
    required this.role,
    required this.token,
  });

  bool get isAnonymous => role == UserRole.anonymous;
  bool get isOrganizer => role == UserRole.organizer;
}

class OrganizerSession extends UserSession {
  final String email;

  const OrganizerSession({
    required super.userId,
    required super.name,
    required this.email,
    required super.token,
  }) : super(role: UserRole.organizer);

  // esto es como el equals, y por las mismas razones que en java, lo esta overrideando
  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) || // si apuntan al mismo espacio de memoria -> true
      other is OrganizerSession && // si las propiedades de los objetos son iguales
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
    return 'OrganizerSession(userId: $userId, email: $email, name: $name, role: $role)';
  }
}

class AnonymousSession extends UserSession {
  final String eventId;

  const AnonymousSession({
    required super.userId,
    required super.name,
    required super.token,
    required this.eventId,
  }) : super(role: UserRole.anonymous);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnonymousSession &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          name == other.name &&
          role == other.role &&
          token == other.token &&
          eventId == other.eventId;

  @override
  int get hashCode =>
      userId.hashCode ^
      name.hashCode ^
      role.hashCode ^
      token.hashCode ^
      eventId.hashCode;

  @override
  String toString() {
    return 'AnonymousSession(userId: $userId, name: $name, role: $role, eventId: $eventId)';
  }
}
