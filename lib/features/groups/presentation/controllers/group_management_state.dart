import 'package:flutter/foundation.dart';

enum GroupManagementActionStatus { idle, loading, success, error }

enum GroupManagementErrorReason { none, forbidden }

typedef GroupMemberKey = ({String groupId, String userId});

class GroupManagementState {
  final GroupManagementActionStatus addMemberStatus;
  final GroupManagementActionStatus renameStatus;
  final GroupManagementActionStatus leaveStatus;
  final GroupManagementErrorReason addMemberErrorReason;
  final GroupManagementErrorReason renameErrorReason;
  final GroupManagementErrorReason leaveErrorReason;
  final Set<GroupMemberKey> addedMembers;
  final Set<GroupMemberKey>? _addingMembers;

  GroupManagementState({
    this.addMemberStatus = GroupManagementActionStatus.idle,
    this.renameStatus = GroupManagementActionStatus.idle,
    this.leaveStatus = GroupManagementActionStatus.idle,
    this.addMemberErrorReason = GroupManagementErrorReason.none,
    this.renameErrorReason = GroupManagementErrorReason.none,
    this.leaveErrorReason = GroupManagementErrorReason.none,
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
    GroupManagementErrorReason? addMemberErrorReason,
    GroupManagementErrorReason? renameErrorReason,
    GroupManagementErrorReason? leaveErrorReason,
    Set<GroupMemberKey>? addedMembers,
    Set<GroupMemberKey>? addingMembers,
  }) {
    return GroupManagementState(
      addMemberStatus: addMemberStatus ?? this.addMemberStatus,
      renameStatus: renameStatus ?? this.renameStatus,
      leaveStatus: leaveStatus ?? this.leaveStatus,
      addMemberErrorReason: addMemberErrorReason ?? this.addMemberErrorReason,
      renameErrorReason: renameErrorReason ?? this.renameErrorReason,
      leaveErrorReason: leaveErrorReason ?? this.leaveErrorReason,
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
          addMemberErrorReason == other.addMemberErrorReason &&
          renameErrorReason == other.renameErrorReason &&
          leaveErrorReason == other.leaveErrorReason &&
          setEquals(addedMembers, other.addedMembers) &&
          setEquals(addingMembers, other.addingMembers);

  @override
  int get hashCode => Object.hash(
    addMemberStatus,
    renameStatus,
    leaveStatus,
    addMemberErrorReason,
    renameErrorReason,
    leaveErrorReason,
    Object.hashAll(addedMembers),
    Object.hashAll(addingMembers),
  );
}
