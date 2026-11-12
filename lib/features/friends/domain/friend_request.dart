import 'person.dart';

// Solicitud de amistad dirigida o recibida por la persona actual.
class FriendRequest {
  final String id;
  final Person user;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.user,
    required this.createdAt,
  });

  FriendRequest copyWith({String? id, Person? user, DateTime? createdAt}) {
    return FriendRequest(
      id: id ?? this.id,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendRequest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          user == other.user &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, user, createdAt);

  @override
  String toString() {
    return 'FriendRequest(id: $id, user: $user, createdAt: $createdAt)';
  }
}
