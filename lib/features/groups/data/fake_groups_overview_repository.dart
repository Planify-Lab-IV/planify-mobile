import '../../events/domain/event_status.dart';
import '../domain/group_overview.dart';
import '../domain/groups_overview_repository.dart';

class FakeGroupsOverviewRepository implements GroupsOverviewRepository {
  final Duration delay;
  final bool shouldThrowError;
  List<GroupOverview> _groups;

  FakeGroupsOverviewRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
    List<GroupOverview>? initialGroups,
  }) : _groups = List.unmodifiable(
         initialGroups ??
             [
               GroupOverview(
                 id: 'grp-amigos',
                 name: 'Amigos',
                 memberCount: 4,
                 events: const [
                   GroupEventSummary(
                     id: 'evt-123',
                     name: 'Cumpleaños de Lucas',
                     status: EventStatus.active,
                     location: 'Casa de Lucas',
                   ),
                   GroupEventSummary(
                     id: 'evt-asado-amigos',
                     name: 'Asado con Amigos',
                     status: EventStatus.active,
                     location: 'Club de Campo',
                   ),
                   GroupEventSummary(
                     id: 'evt-fake-demo',
                     name: 'Evento Demo',
                     status: EventStatus.active,
                     location: 'Av. Corrientes 1234',
                   ),
                 ],
               ),
               GroupOverview(
                 id: 'grp-familia',
                 name: 'Familia',
                 memberCount: 6,
                 events: [
                   GroupEventSummary(
                     id: 'evt-almuerzo-familia',
                     name: 'Almuerzo familiar',
                     status: EventStatus.confirmed,
                     startDateTime: DateTime(2026, 12, 20, 13),
                     location: 'Casa de la abuela',
                   ),
                 ],
               ),
               GroupOverview(
                 id: 'grp-trabajo',
                 name: 'Trabajo',
                 memberCount: 8,
                 events: const [],
               ),
             ],
       );

  @override
  Future<List<GroupOverview>> getMyGroupsOverview() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldThrowError) throw Exception('Could not load groups overview');
    return List.unmodifiable(_groups);
  }

  void incrementMemberCount(String groupId) {
    _replaceGroup(groupId, (group) {
      return GroupOverview(
        id: group.id,
        name: group.name,
        memberCount: group.memberCount + 1,
        events: group.events,
      );
    });
  }

  void renameGroup(String groupId, String name) {
    _replaceGroup(groupId, (group) {
      return GroupOverview(
        id: group.id,
        name: name,
        memberCount: group.memberCount,
        events: group.events,
      );
    });
  }

  void removeGroup(String groupId) {
    final originalLength = _groups.length;
    _groups = List.unmodifiable(_groups.where((group) => group.id != groupId));
    if (_groups.length == originalLength) {
      throw StateError('Group $groupId was not found');
    }
  }

  void _replaceGroup(
    String groupId,
    GroupOverview Function(GroupOverview group) replacement,
  ) {
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index == -1) throw StateError('Group $groupId was not found');

    final updatedGroups = List<GroupOverview>.of(_groups);
    updatedGroups[index] = replacement(_groups[index]);
    _groups = List.unmodifiable(updatedGroups);
  }
}
