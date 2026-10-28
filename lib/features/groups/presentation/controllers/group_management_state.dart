import 'package:flutter/foundation.dart';

enum GroupManagementActionStatus { idle, loading, success, error }

typedef GroupMemberKey = ({String groupId, String userId});

class GroupManagementState {
  final GroupManagementActionStatus addMemberStatus;
  final GroupManagementActionStatus renameStatus;
  final GroupManagementActionStatus leaveStatus;
  final Set<GroupMemberKey> addedMembers;
  final Set<GroupMemberKey>? _addingMembers;

  GroupManagementState({
    this.addMemberStatus = GroupManagementActionStatus.idle,
    this.renameStatus = GroupManagementActionStatus.idle,
    this.leaveStatus = GroupManagementActionStatus.idle,
    Set<GroupMemberKey> addedMembers = const {},
    Set<GroupMemberKey> addingMembers = const {},
  }) : addedMembers = Set.unmodifiable(addedMembers),
       _addingMembers = Set.unmodifiable(addingMembers);

  Set<GroupMemberKey> get addingMembers => _addingMembers ?? const {};

  bool get isAddingMember => addingMembers.isNotEmpty;

  bool get isRenaming => renameStatus == GroupManagementActionStatus.loading;

  bool get isLeaving => leaveStatus == GroupManagementActionStatus.loading;

  bool isMemberAdded({required String groupId, required String userId}) {
    return addedMembers.contains((groupId: groupId, userId: userId));
  }

  bool isMemberBeingAdded({required String groupId, required String userId}) {
    return addingMembers.contains((groupId: groupId, userId: userId));
  }

  GroupManagementState copyWith({
    GroupManagementActionStatus? addMemberStatus,
    GroupManagementActionStatus? renameStatus,
    GroupManagementActionStatus? leaveStatus,
    Set<GroupMemberKey>? addedMembers,
    Set<GroupMemberKey>? addingMembers,
  }) {
    return GroupManagementState(
      addMemberStatus: addMemberStatus ?? this.addMemberStatus,
      renameStatus: renameStatus ?? this.renameStatus,
      leaveStatus: leaveStatus ?? this.leaveStatus,
      addedMembers: addedMembers ?? this.addedMembers,
      addingMembers: addingMembers ?? this.addingMembers,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupManagementState &&
          runtimeType == other.runtimeType &&
          addMemberStatus == other.addMemberStatus &&
          renameStatus == other.renameStatus &&
          leaveStatus == other.leaveStatus &&
          setEquals(addedMembers, other.addedMembers) &&
          setEquals(addingMembers, other.addingMembers);

  @override
  int get hashCode => Object.hash(
    addMemberStatus,
    renameStatus,
    leaveStatus,
    Object.hashAll(addedMembers),
    Object.hashAll(addingMembers),
  );
}
