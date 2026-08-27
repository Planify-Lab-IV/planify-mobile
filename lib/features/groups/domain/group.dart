class Group {
  final String id;
  final String name;
  final int memberCount;

  const Group({required this.id, required this.name, this.memberCount = 0});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Group &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          memberCount == other.memberCount;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ memberCount.hashCode;

  @override
  String toString() => 'Group(id: $id, name: $name, memberCount: $memberCount)';
}
