import 'group_overview.dart';

abstract interface class GroupsOverviewRepository {
  Future<List<GroupOverview>> getMyGroupsOverview();
}
