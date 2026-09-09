import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/http_groups_repository.dart';
import '../../domain/group.dart';
import '../../domain/groups_repository.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return HttpGroupsRepository(dio: ref.watch(dioClientProvider));
});

final myGroupsProvider = FutureProvider.autoDispose<List<Group>>((ref) async {
  final repository = ref.watch(groupsRepositoryProvider);
  return repository.getMyGroups();
});
