class Event {
  final String id;
  final String name;
  final String location;
  final String groupId;
  final String groupName;
  final List<String> memberIdentifiers;
  final DateTime createdAt;

  const Event({
    required this.id,
    required this.name,
    required this.location,
    required this.groupId,
    required this.groupName,
    this.memberIdentifiers = const [],
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          location == other.location &&
          groupId == other.groupId &&
          groupName == other.groupName &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      location.hashCode ^
      groupId.hashCode ^
      groupName.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'Event(id: $id, name: $name, location: $location, groupName: $groupName)';
  }
}
