abstract interface class GroupManagementRepository {
  Future<void> addMember({required String groupId, required String userId});

  Future<void> renameGroup({required String groupId, required String name});

  Future<void> leaveGroup(String groupId);
}
