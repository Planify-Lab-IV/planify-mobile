import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/group_exceptions.dart';
import '../../domain/group_management_repository.dart';
import 'group_management_state.dart';

class GroupManagementNotifier extends StateNotifier<GroupManagementState> {
  final GroupManagementRepository repository;
  final void Function()? onGroupManagementSucceeded;
  final void Function()? onGroupManagementForbidden;

  GroupManagementNotifier({
    required this.repository,
    this.onGroupManagementSucceeded,
    this.onGroupManagementForbidden,
  }) : super(GroupManagementState());

  void resetRenameStatus() {
    if (state.isRenaming ||
        state.renameStatus == GroupManagementActionStatus.idle) {
      return;
    }
    state = state.copyWith(
      renameStatus: GroupManagementActionStatus.idle,
      renameErrorReason: GroupManagementErrorReason.none,
    );
  }

  void resetLeaveStatus() {
    if (state.isLeaving ||
        state.leaveStatus == GroupManagementActionStatus.idle) {
      return;
    }
    state = state.copyWith(
      leaveStatus: GroupManagementActionStatus.idle,
      leaveErrorReason: GroupManagementErrorReason.none,
    );
  }

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
      addMemberErrorReason: GroupManagementErrorReason.none,
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
    } catch (error) {
      if (!mounted) return false;
      final pendingMembers = {...state.addingMembers}..remove(member);
      state = state.copyWith(
        addMemberStatus: pendingMembers.isEmpty
            ? GroupManagementActionStatus.error
            : GroupManagementActionStatus.loading,
        addMemberErrorReason: _errorReason(error),
        addingMembers: pendingMembers,
      );
      if (error is GroupForbiddenException) {
        onGroupManagementForbidden?.call();
      }
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

    state = state.copyWith(
      renameStatus: GroupManagementActionStatus.loading,
      renameErrorReason: GroupManagementErrorReason.none,
    );
    try {
      await repository.renameGroup(
        groupId: normalizedGroupId,
        name: normalizedName,
      );
      if (!mounted) return false;

      state = state.copyWith(renameStatus: GroupManagementActionStatus.success);
      onGroupManagementSucceeded?.call();
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        renameStatus: GroupManagementActionStatus.error,
        renameErrorReason: _errorReason(error),
      );
      if (error is GroupForbiddenException) {
        onGroupManagementForbidden?.call();
      }
      return false;
    }
  }

  Future<bool> leaveGroup(String groupId) async {
    final normalizedGroupId = groupId.trim();
    if (normalizedGroupId.isEmpty || state.isLeaving) return false;

    state = state.copyWith(
      leaveStatus: GroupManagementActionStatus.loading,
      leaveErrorReason: GroupManagementErrorReason.none,
    );
    try {
      await repository.leaveGroup(normalizedGroupId);
      if (!mounted) return false;

      state = state.copyWith(leaveStatus: GroupManagementActionStatus.success);
      onGroupManagementSucceeded?.call();
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        leaveStatus: GroupManagementActionStatus.error,
        leaveErrorReason: _errorReason(error),
      );
      if (error is GroupForbiddenException) {
        onGroupManagementForbidden?.call();
      }
      return false;
    }
  }

  GroupManagementErrorReason _errorReason(Object error) {
    return error is GroupForbiddenException
        ? GroupManagementErrorReason.forbidden
        : GroupManagementErrorReason.none;
  }
}
