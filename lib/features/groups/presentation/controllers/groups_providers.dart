import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/http_group_management_repository.dart';
import '../../data/http_groups_repository.dart';
import '../../data/http_groups_overview_repository.dart';
import '../../domain/group.dart';
import '../../domain/group_management_repository.dart';
import '../../domain/groups_repository.dart';
import '../../domain/group_overview.dart';
import '../../domain/groups_overview_repository.dart';
import 'group_management_notifier.dart';
import 'group_management_state.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return HttpGroupsRepository(dio: ref.watch(dioClientProvider));
});

final myGroupsProvider = FutureProvider.autoDispose<List<Group>>((ref) async {
  final repository = ref.watch(groupsRepositoryProvider);
  return repository.getMyGroups();
});

final groupsOverviewRepositoryProvider = Provider<GroupsOverviewRepository>(
  (ref) => HttpGroupsOverviewRepository(dio: ref.watch(dioClientProvider)),
);

final groupsOverviewProvider = FutureProvider.autoDispose<List<GroupOverview>>(
  (ref) => ref.watch(groupsOverviewRepositoryProvider).getMyGroupsOverview(),
);

final groupManagementRepositoryProvider = Provider<GroupManagementRepository>(
  (ref) => HttpGroupManagementRepository(dio: ref.watch(dioClientProvider)),
);

final groupManagementNotifierProvider =
    StateNotifierProvider<GroupManagementNotifier, GroupManagementState>((ref) {
      return GroupManagementNotifier(
        repository: ref.watch(groupManagementRepositoryProvider),
        onGroupManagementSucceeded: () =>
            ref.invalidate(groupsOverviewProvider),
        onGroupManagementForbidden: () =>
            ref.invalidate(groupsOverviewProvider),
      );
    });

final selectedGroupIdProvider = StateProvider<String?>((ref) => null);

final selectedGroupOverviewProvider = Provider.autoDispose<GroupOverview?>((
  ref,
) {
  final groups = ref.watch(groupsOverviewProvider).asData?.value;
  final id = ref.watch(selectedGroupIdProvider);
  if (groups == null || groups.isEmpty) return null;
  for (final group in groups) {
    if (group.id == id) return group;
  }
  return groups.first;
});
