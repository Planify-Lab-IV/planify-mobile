import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/group_management_repository.dart';
import 'group_management_state.dart';

class GroupManagementNotifier extends StateNotifier<GroupManagementState> {
  final GroupManagementRepository repository;
  final void Function()? onGroupManagementSucceeded;

  GroupManagementNotifier({
    required this.repository,
    this.onGroupManagementSucceeded,
  }) : super(GroupManagementState());

  Future<bool> addMember({
    required String groupId,
    required String userId,
  }) async {
    final normalizedGroupId = groupId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedGroupId.isEmpty ||
        normalizedUserId.isEmpty ||
        state.isMemberBeingAdded(
          groupId: normalizedGroupId,
          userId: normalizedUserId,
        )) {
      return false;
    }

    final member = (groupId: normalizedGroupId, userId: normalizedUserId);
    state = state.copyWith(
      addMemberStatus: GroupManagementActionStatus.loading,
      addingMembers: {...state.addingMembers, member},
    );
    try {
      await repository.addMember(
        groupId: normalizedGroupId,
        userId: normalizedUserId,
      );
      if (!mounted) return false;

      final pendingMembers = {...state.addingMembers}..remove(member);
      state = state.copyWith(
        addMemberStatus: pendingMembers.isEmpty
            ? GroupManagementActionStatus.success
            : GroupManagementActionStatus.loading,
        addedMembers: {...state.addedMembers, member},
        addingMembers: pendingMembers,
      );
      onGroupManagementSucceeded?.call();
      return true;
    } catch (_) {
      if (!mounted) return false;
      final pendingMembers = {...state.addingMembers}..remove(member);
      state = state.copyWith(
        addMemberStatus: pendingMembers.isEmpty
            ? GroupManagementActionStatus.error
            : GroupManagementActionStatus.loading,
        addingMembers: pendingMembers,
      );
      return false;
    }
  }

  Future<bool> renameGroup({
    required String groupId,
    required String name,
  }) async {
    final normalizedGroupId = groupId.trim();
    final normalizedName = name.trim();
    if (normalizedGroupId.isEmpty ||
        normalizedName.isEmpty ||
        normalizedName.length > 80 ||
        state.isRenaming) {
      return false;
    }

    state = state.copyWith(renameStatus: GroupManagementActionStatus.loading);
    try {
      await repository.renameGroup(
        groupId: normalizedGroupId,
        name: normalizedName,
      );
      if (!mounted) return false;

      state = state.copyWith(renameStatus: GroupManagementActionStatus.success);
      onGroupManagementSucceeded?.call();
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(renameStatus: GroupManagementActionStatus.error);
      return false;
    }
  }

  Future<bool> leaveGroup(String groupId) async {
    final normalizedGroupId = groupId.trim();
    if (normalizedGroupId.isEmpty || state.isLeaving) return false;

    state = state.copyWith(leaveStatus: GroupManagementActionStatus.loading);
    try {
      await repository.leaveGroup(normalizedGroupId);
      if (!mounted) return false;

      state = state.copyWith(leaveStatus: GroupManagementActionStatus.success);
      onGroupManagementSucceeded?.call();
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(leaveStatus: GroupManagementActionStatus.error);
      return false;
    }
  }
}
