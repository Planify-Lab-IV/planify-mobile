enum UserRole { organizer, anonymous }

sealed class UserSession {
  final String name;
  final UserRole role;
  final String token;

  const UserSession({
    required this.name,
    required this.role,
    required this.token,
  });

  bool get isAnonymous => role == UserRole.anonymous;
  bool get isOrganizer => role == UserRole.organizer;
}

class OrganizerSession extends UserSession {
  final String userId;
  final String email;
  final String username;

  const OrganizerSession({
    required this.userId,
    required super.name,
    required this.email,
    required this.username,
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
          username == other.username &&
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
      username.hashCode ^
      name.hashCode ^
      role.hashCode ^
      token.hashCode;

  @override
  String toString() {
    return 'OrganizerSession(userId: $userId, username: $username, email: $email, name: $name, role: $role)';
  }
}

class AnonymousSession extends UserSession {
  final String participantId;
  final String eventId;

  const AnonymousSession({
    required this.participantId,
    required super.name,
    required super.token,
    required this.eventId,
  }) : super(role: UserRole.anonymous);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnonymousSession &&
          runtimeType == other.runtimeType &&
          participantId == other.participantId &&
          name == other.name &&
          role == other.role &&
          token == other.token &&
          eventId == other.eventId;

  @override
  int get hashCode =>
      participantId.hashCode ^
      name.hashCode ^
      role.hashCode ^
      token.hashCode ^
      eventId.hashCode;

  @override
  String toString() {
    return 'AnonymousSession(participantId: $participantId, name: $name, role: $role, eventId: $eventId)';
  }
}
