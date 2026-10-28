import 'package:flutter/foundation.dart';

enum GroupManagementActionStatus { idle, loading, success, error }

class GroupManagementState {
  final GroupManagementActionStatus addMemberStatus;
  final GroupManagementActionStatus renameStatus;
  final GroupManagementActionStatus leaveStatus;
  final Set<String> addedMemberIds;

  GroupManagementState({
    this.addMemberStatus = GroupManagementActionStatus.idle,
    this.renameStatus = GroupManagementActionStatus.idle,
    this.leaveStatus = GroupManagementActionStatus.idle,
    Set<String> addedMemberIds = const {},
  }) : addedMemberIds = Set.unmodifiable(addedMemberIds);

  bool get isAddingMember =>
      addMemberStatus == GroupManagementActionStatus.loading;

  bool get isRenaming => renameStatus == GroupManagementActionStatus.loading;

  bool get isLeaving => leaveStatus == GroupManagementActionStatus.loading;

  bool isMemberAdded(String userId) => addedMemberIds.contains(userId);

  GroupManagementState copyWith({
    GroupManagementActionStatus? addMemberStatus,
    GroupManagementActionStatus? renameStatus,
    GroupManagementActionStatus? leaveStatus,
    Set<String>? addedMemberIds,
  }) {
    return GroupManagementState(
      addMemberStatus: addMemberStatus ?? this.addMemberStatus,
      renameStatus: renameStatus ?? this.renameStatus,
      leaveStatus: leaveStatus ?? this.leaveStatus,
      addedMemberIds: addedMemberIds ?? this.addedMemberIds,
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
          setEquals(addedMemberIds, other.addedMemberIds);

  @override
  int get hashCode => Object.hash(
    addMemberStatus,
    renameStatus,
    leaveStatus,
    Object.hashAll(addedMemberIds),
  );
}
