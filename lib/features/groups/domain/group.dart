import 'package:flutter/foundation.dart';

class Group {
  final String id;
  final String name;
  final List<String> memberIdentifiers;

  const Group({
    required this.id,
    required this.name,
    this.memberIdentifiers = const [],
  });

  int get memberCount => memberIdentifiers.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Group &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          listEquals(memberIdentifiers, other.memberIdentifiers);

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ Object.hashAll(memberIdentifiers);

  @override
  String toString() => 'Group(id: $id, name: $name, memberCount: $memberCount)';
}
