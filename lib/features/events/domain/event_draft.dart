import 'package:flutter/foundation.dart';

class EventDraft {
  // informacion del paso 1
  final String name;
  final String location;

  // informacion del paso 2
  final bool isNewGroup;
  final String? selectedGroupId;
  final String? selectedGroupName;
  final String? newGroupName;
  final List<String> newGroupMembers;

  const EventDraft({
    this.name = '',
    this.location = '',
    this.isNewGroup = false,
    this.selectedGroupId,
    this.selectedGroupName,
    this.newGroupName,
    this.newGroupMembers = const [],
  });

  const EventDraft.empty() : this();

  bool get isEmpty =>
      name.trim().isEmpty &&
      location.trim().isEmpty &&
      selectedGroupId == null &&
      (newGroupName == null || newGroupName!.trim().isEmpty) &&
      newGroupMembers.isEmpty;

  bool get isStep1Valid => name.trim().isNotEmpty && location.trim().isNotEmpty;

  bool get isStep2Valid {
    if (isNewGroup) {
      return newGroupName != null && newGroupName!.trim().isNotEmpty;
    } else {
      return selectedGroupId != null && selectedGroupId!.trim().isNotEmpty;
    }
  }

  bool get isValid => isStep1Valid && isStep2Valid;

  EventDraft copyWith({
    String? name,
    String? location,
    bool? isNewGroup,
    String? selectedGroupId,
    String? selectedGroupName,
    String? newGroupName,
    List<String>? newGroupMembers,
    bool clearSelectedGroup = false,
  }) {
    return EventDraft(
      name: name ?? this.name,
      location: location ?? this.location,
      isNewGroup: isNewGroup ?? this.isNewGroup,
      selectedGroupId: clearSelectedGroup
          ? null
          : (selectedGroupId ?? this.selectedGroupId),
      selectedGroupName: clearSelectedGroup
          ? null
          : (selectedGroupName ?? this.selectedGroupName),
      newGroupName: newGroupName ?? this.newGroupName,
      newGroupMembers: newGroupMembers ?? this.newGroupMembers,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventDraft &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          location == other.location &&
          isNewGroup == other.isNewGroup &&
          selectedGroupId == other.selectedGroupId &&
          selectedGroupName == other.selectedGroupName &&
          newGroupName == other.newGroupName &&
          listEquals(newGroupMembers, other.newGroupMembers);

  @override
  int get hashCode =>
      name.hashCode ^
      location.hashCode ^
      isNewGroup.hashCode ^
      selectedGroupId.hashCode ^
      selectedGroupName.hashCode ^
      newGroupName.hashCode ^
      Object.hashAll(newGroupMembers);

  @override
  String toString() {
    return 'EventDraft(name: $name, location: $location, isNewGroup: $isNewGroup, selectedGroupId: $selectedGroupId, newGroupName: $newGroupName, membersCount: ${newGroupMembers.length})';
  }
}
