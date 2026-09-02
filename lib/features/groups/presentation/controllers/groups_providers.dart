import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/fake_groups_repository.dart';
import '../../domain/group.dart';
import '../../domain/groups_repository.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return FakeGroupsRepository();
});

final myGroupsProvider = FutureProvider<List<Group>>((ref) async {
  final repository = ref.watch(groupsRepositoryProvider);
  return repository.getMyGroups();
});
