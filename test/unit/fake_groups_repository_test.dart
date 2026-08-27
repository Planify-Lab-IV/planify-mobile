import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/groups/data/fake_groups_repository.dart';
import 'package:planify/features/groups/domain/group.dart';

void main() {
  group('FakeGroupsRepository', () {
    late FakeGroupsRepository repository;

    setUp(() {
      repository = FakeGroupsRepository(delay: Duration.zero);
    });

    test('getMyGroups devuelve lista predeterminada de grupos', () async {
      final groups = await repository.getMyGroups();

      expect(groups, isNotEmpty);
      expect(groups.length, equals(3));
      expect(groups.first.name, equals('Amigos del Fútbol'));
    });

    test(
      'getMyGroups arroja excepción cuando shouldThrowError es true',
      () async {
        final errorRepo = FakeGroupsRepository(
          delay: Duration.zero,
          shouldThrowError: true,
        );

        expect(() => errorRepo.getMyGroups(), throwsException);
      },
    );

    test('addGroup agrega un nuevo grupo a la lista', () async {
      const newGroup = Group(
        id: 'grp-custom',
        name: 'Nuevo Grupo Test',
        memberCount: 2,
      );
      repository.addGroup(newGroup);

      final groups = await repository.getMyGroups();
      expect(groups.any((g) => g.id == 'grp-custom'), isTrue);
    });
  });
}
