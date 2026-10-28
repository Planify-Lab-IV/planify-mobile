import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/groups/data/fake_group_management_repository.dart';
import 'package:planify/features/groups/data/fake_groups_overview_repository.dart';
import 'package:planify/features/groups/presentation/controllers/groups_providers.dart';

void main() {
  test('the management fake shares an overridden fake overview', () async {
    final overview = FakeGroupsOverviewRepository(delay: Duration.zero);
    final container = ProviderContainer(
      overrides: [groupsOverviewRepositoryProvider.overrideWithValue(overview)],
    );
    addTearDown(container.dispose);

    final repository = container.read(groupManagementRepositoryProvider);

    expect(repository, isA<FakeGroupManagementRepository>());
    await repository.renameGroup(groupId: 'grp-amigos', name: 'Amistades');
    expect((await overview.getMyGroupsOverview()).first.name, 'Amistades');
  });
}
