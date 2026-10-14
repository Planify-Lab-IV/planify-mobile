import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/groups/data/fake_groups_overview_repository.dart';
import 'package:planify/features/groups/domain/group_overview.dart';
import 'package:planify/features/events/domain/event_status.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';

void main() {
  test(
    'every overview event exists with matching data in the events fake',
    () async {
      final overview = await FakeGroupsOverviewRepository(
        delay: Duration.zero,
      ).getMyGroupsOverview();
      final events = FakeEventsRepository(delay: Duration.zero);
      for (final group in overview) {
        for (final summary in group.events) {
          final detail = await events.getEvent(summary.id);
          expect(detail, isNotNull);
          expect(detail!.groupId, group.id);
          expect(detail.name, summary.name);
          expect(detail.location, summary.location);
          expect(detail.status, summary.status);
          expect(detail.startDateTime, summary.startDateTime);
        }
      }
    },
  );
  test(
    'demo contains shared event IDs, a confirmed event and an empty group',
    () async {
      final groups = await FakeGroupsOverviewRepository(
        delay: Duration.zero,
      ).getMyGroupsOverview();
      expect(groups.first.id, 'grp-amigos');
      expect(groups.first.events.map((e) => e.id), [
        'evt-123',
        'evt-asado-amigos',
        'evt-fake-demo',
      ]);
      expect(groups[1].events.single.status, EventStatus.confirmed);
      expect(groups[1].events.single.startDateTime, isNotNull);
      expect(groups.last.events, isEmpty);
      expect(() => groups.clear(), throwsUnsupportedError);
      expect(() => groups.first.events.clear(), throwsUnsupportedError);
    },
  );

  test('injected data is snapshotted including its events', () async {
    final events = <GroupEventSummary>[];
    final group = GroupOverview(
      id: 'g',
      name: 'G',
      memberCount: 1,
      events: events,
    );
    events.add(
      const GroupEventSummary(
        id: 'e',
        name: 'E',
        status: EventStatus.active,
        location: 'L',
      ),
    );
    final input = [group];
    final repository = FakeGroupsOverviewRepository(
      delay: Duration.zero,
      initialGroups: input,
    );
    input.clear();
    expect(await repository.getMyGroupsOverview(), [group]);
    expect(group.events, isEmpty);
  });

  test('empty data and configured failures are supported', () async {
    expect(
      await FakeGroupsOverviewRepository(
        delay: Duration.zero,
        initialGroups: [],
      ).getMyGroupsOverview(),
      isEmpty,
    );
    await expectLater(
      FakeGroupsOverviewRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      ).getMyGroupsOverview(),
      throwsException,
    );
  });

  test('models compare event collections by value', () {
    const event = GroupEventSummary(
      id: 'e',
      name: 'E',
      status: EventStatus.active,
      location: 'L',
    );
    final a = GroupOverview(
      id: 'g',
      name: 'G',
      memberCount: 1,
      events: [event],
    );
    final b = GroupOverview(
      id: 'g',
      name: 'G',
      memberCount: 1,
      events: [event],
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(
      a,
      isNot(GroupOverview(id: 'g', name: 'G', memberCount: 1, events: [])),
    );
  });
}
