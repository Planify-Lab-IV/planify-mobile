import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/groups/domain/group.dart';

void main() {
  group('Group', () {
    test('stores the member count returned by the API', () {
      const group = Group(
        id: 'grp-1',
        name: 'Amigos',
        memberCount: 3,
      );

      expect(group.memberCount, 3);
    });

    test('uses member count for value equality', () {
      const group = Group(id: 'grp-1', name: 'Amigos', memberCount: 3);
      const sameGroup = Group(id: 'grp-1', name: 'Amigos', memberCount: 3);
      const groupWithDifferentCount = Group(
        id: 'grp-1',
        name: 'Amigos',
        memberCount: 2,
      );

      expect(group, sameGroup);
      expect(group.hashCode, sameGroup.hashCode);
      expect(group, isNot(groupWithDifferentCount));
    });
  });
}
