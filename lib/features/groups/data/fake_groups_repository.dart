import '../domain/group.dart';
import '../domain/groups_repository.dart';

class FakeGroupsRepository implements GroupsRepository {
  final Duration delay;
  final bool shouldThrowError;
  List<Group> _groups;

  FakeGroupsRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
    List<Group>? initialGroups,
  }) : _groups =
           initialGroups ??
           const [
             Group(
               id: 'grp-1',
               name: 'Amigos del Fútbol',
               memberIdentifiers: [
                 'juan@gmail.com',
                 'pedro@gmail.com',
                 'lucas@gmail.com',
               ],
             ),
             Group(
               id: 'grp-2',
               name: 'Compañeros de Trabajo',
               memberIdentifiers: ['ana@work.com', 'carlos@work.com'],
             ),
             Group(
               id: 'grp-3',
               name: 'Familia',
               memberIdentifiers: ['mama@gmail.com', 'papa@gmail.com'],
             ),
           ];

  @override
  Future<List<Group>> getMyGroups() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (shouldThrowError) {
      throw Exception('Error al obtener los grupos');
    }
    return List.unmodifiable(_groups);
  }

  void addGroup(Group group) {
    _groups = [..._groups, group];
  }
}
