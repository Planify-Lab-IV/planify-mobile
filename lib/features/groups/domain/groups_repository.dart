import 'group.dart';

abstract class GroupsRepository {
  Future<List<Group>> getMyGroups();
}
