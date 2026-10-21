// Datos públicos de una persona disponible en la lista de amigos.
enum FriendRelationship { none, requestSent, requestReceived, friend }

class Person {
  final String id;
  final String name;
  final String username;
  final FriendRelationship relationship;
  final String? requestId;

  const Person({
    required this.id,
    required this.name,
    required this.username,
    required this.relationship,
    this.requestId,
  });

  Person copyWith({
    String? id,
    String? name,
    String? username,
    FriendRelationship? relationship,
    String? requestId,
    bool clearRequestId = false,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      relationship: relationship ?? this.relationship,
      requestId: clearRequestId ? null : requestId ?? this.requestId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          username == other.username &&
          relationship == other.relationship &&
          requestId == other.requestId;

  @override
  int get hashCode => Object.hash(id, name, username, relationship, requestId);

  @override
  String toString() {
    return 'Person(id: $id, name: $name, username: $username, relationship: $relationship, requestId: $requestId)';
  }
}
