import '../domain/group_management_repository.dart';
import 'fake_groups_overview_repository.dart';

/// Simula las acciones de gestión hasta que la integración HTTP esté disponible.
class FakeGroupManagementRepository implements GroupManagementRepository {
  final FakeGroupsOverviewRepository overviewRepository;
  final Duration delay;
  final bool shouldThrowError;

  final List<({String groupId, String userId})> addMemberRequests = [];
  final List<({String groupId, String name})> renameGroupRequests = [];
  final List<String> leaveGroupRequests = [];
  final Set<({String groupId, String userId})> _addedMembers = {};

  FakeGroupManagementRepository({
    required this.overviewRepository,
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
  });

  @override
  Future<void> addMember({
    required String groupId,
    required String userId,
  }) async {
    addMemberRequests.add((groupId: groupId, userId: userId));
    await _waitOrThrow();

    final member = (groupId: groupId, userId: userId);
    if (_addedMembers.contains(member)) return;

    overviewRepository.incrementMemberCount(groupId);
    _addedMembers.add(member);
  }

  @override
  Future<void> renameGroup({
    required String groupId,
    required String name,
  }) async {
    renameGroupRequests.add((groupId: groupId, name: name));
    await _waitOrThrow();
    overviewRepository.renameGroup(groupId, name);
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    leaveGroupRequests.add(groupId);
    await _waitOrThrow();
    overviewRepository.removeGroup(groupId);
  }

  Future<void> _waitOrThrow() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldThrowError) throw Exception('Could not manage group');
  }
}
