import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/domain/event_status.dart';
import 'package:planify/features/groups/data/fake_group_management_repository.dart';
import 'package:planify/features/groups/data/fake_groups_overview_repository.dart';
import 'package:planify/features/groups/domain/group_overview.dart';

void main() {
  FakeGroupsOverviewRepository overviewRepository() {
    return FakeGroupsOverviewRepository(
      delay: Duration.zero,
      initialGroups: [
        GroupOverview(
          id: 'group-1',
          name: 'Amigos',
          memberCount: 2,
          events: const [
            GroupEventSummary(
              id: 'event-1',
              name: 'Cena',
              status: EventStatus.active,
              location: 'Casa',
            ),
          ],
        ),
        GroupOverview(
          id: 'group-2',
          name: 'Familia',
          memberCount: 3,
          events: const [],
        ),
      ],
    );
  }

  group('FakeGroupManagementRepository', () {
    test('records an added member and updates the shared overview', () async {
      final overview = overviewRepository();
      final repository = FakeGroupManagementRepository(
        overviewRepository: overview,
        delay: Duration.zero,
      );

      await repository.addMember(groupId: 'group-1', userId: 'user-1');

      expect(repository.addMemberRequests, [
        (groupId: 'group-1', userId: 'user-1'),
      ]);
      expect(
        (await overview.getMyGroupsOverview()).first.memberCount,
        equals(3),
      );
    });

    test('adding the same member twice is idempotent', () async {
      final overview = overviewRepository();
      final repository = FakeGroupManagementRepository(
        overviewRepository: overview,
        delay: Duration.zero,
      );

      await repository.addMember(groupId: 'group-1', userId: 'user-1');
      await repository.addMember(groupId: 'group-1', userId: 'user-1');

      expect(repository.addMemberRequests, hasLength(2));
      expect(
        (await overview.getMyGroupsOverview()).first.memberCount,
        equals(3),
      );
    });

    test('records a rename and preserves the group events', () async {
      final overview = overviewRepository();
      final repository = FakeGroupManagementRepository(
        overviewRepository: overview,
        delay: Duration.zero,
      );

      await repository.renameGroup(groupId: 'group-1', name: 'Amigos 2026');

      final group = (await overview.getMyGroupsOverview()).first;
      expect(repository.renameGroupRequests, [
        (groupId: 'group-1', name: 'Amigos 2026'),
      ]);
      expect(group.name, 'Amigos 2026');
      expect(group.events.single.id, 'event-1');
    });

    test(
      'records a leave operation and removes the group from the overview',
      () async {
        final overview = overviewRepository();
        final repository = FakeGroupManagementRepository(
          overviewRepository: overview,
          delay: Duration.zero,
        );

        await repository.leaveGroup('group-1');

        expect(repository.leaveGroupRequests, ['group-1']);
        expect(
          (await overview.getMyGroupsOverview()).map((group) => group.id),
          ['group-2'],
        );
      },
    );

    test(
      'records failed requests without mutating the shared overview',
      () async {
        final overview = overviewRepository();
        final repository = FakeGroupManagementRepository(
          overviewRepository: overview,
          delay: Duration.zero,
          shouldThrowError: true,
        );

        await expectLater(
          repository.renameGroup(groupId: 'group-1', name: 'Renombrado'),
          throwsException,
        );

        expect(repository.renameGroupRequests, [
          (groupId: 'group-1', name: 'Renombrado'),
        ]);
        expect((await overview.getMyGroupsOverview()).first.name, 'Amigos');
      },
    );
  });
}
