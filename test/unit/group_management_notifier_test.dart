import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/groups/domain/group_management_repository.dart';
import 'package:planify/features/groups/presentation/controllers/group_management_notifier.dart';
import 'package:planify/features/groups/presentation/controllers/group_management_state.dart';

void main() {
  GroupManagementNotifier notifier(
    _RecordingGroupManagementRepository repository, {
    void Function()? onSuccess,
  }) {
    return GroupManagementNotifier(
      repository: repository,
      onGroupManagementSucceeded: onSuccess,
    );
  }

  group('GroupManagementNotifier', () {
    test(
      'updates each action status and invalidates after successful actions',
      () async {
        final repository = _RecordingGroupManagementRepository();
        var successfulActions = 0;
        final groupNotifier = notifier(
          repository,
          onSuccess: () => successfulActions++,
        );

        expect(
          await groupNotifier.addMember(
            groupId: ' group-1 ',
            userId: ' user-1 ',
          ),
          isTrue,
        );
        expect(
          groupNotifier.state.addMemberStatus,
          GroupManagementActionStatus.success,
        );
        expect(
          groupNotifier.state.isMemberAdded(
            groupId: 'group-1',
            userId: 'user-1',
          ),
          isTrue,
        );
        expect(repository.addMemberRequests, [
          (groupId: 'group-1', userId: 'user-1'),
        ]);

        expect(
          await groupNotifier.renameGroup(
            groupId: 'group-1',
            name: ' Familia ',
          ),
          isTrue,
        );
        expect(
          groupNotifier.state.renameStatus,
          GroupManagementActionStatus.success,
        );
        expect(repository.renameRequests, [
          (groupId: 'group-1', name: 'Familia'),
        ]);

        expect(await groupNotifier.leaveGroup('group-1'), isTrue);
        expect(
          groupNotifier.state.leaveStatus,
          GroupManagementActionStatus.success,
        );
        expect(repository.leaveRequests, ['group-1']);
        expect(successfulActions, 3);

        groupNotifier.dispose();
      },
    );

    test('reports an error without invalidating the overview', () async {
      final repository = _RecordingGroupManagementRepository()
        ..shouldFail = true;
      var successfulActions = 0;
      final groupNotifier = notifier(
        repository,
        onSuccess: () => successfulActions++,
      );

      expect(
        await groupNotifier.addMember(groupId: 'group-1', userId: 'user-1'),
        isFalse,
      );

      expect(
        groupNotifier.state.addMemberStatus,
        GroupManagementActionStatus.error,
      );
      expect(groupNotifier.state.addedMembers, isEmpty);
      expect(successfulActions, isZero);
      groupNotifier.dispose();
    });

    test('rejects invalid mutations before reaching the repository', () async {
      final repository = _RecordingGroupManagementRepository();
      final groupNotifier = notifier(repository);

      expect(
        await groupNotifier.addMember(groupId: ' ', userId: 'user-1'),
        isFalse,
      );
      expect(
        await groupNotifier.renameGroup(groupId: 'group-1', name: ' '),
        isFalse,
      );
      expect(
        await groupNotifier.renameGroup(groupId: 'group-1', name: 'a' * 81),
        isFalse,
      );
      expect(await groupNotifier.leaveGroup(' '), isFalse);
      expect(repository.addMemberRequests, isEmpty);
      expect(repository.renameRequests, isEmpty);
      expect(repository.leaveRequests, isEmpty);
      groupNotifier.dispose();
    });

    test('blocks a duplicate action while it is loading', () async {
      final repository = _RecordingGroupManagementRepository()
        ..addMemberCompletion = Completer<void>();
      final groupNotifier = notifier(repository);

      final firstAdd = groupNotifier.addMember(
        groupId: 'group-1',
        userId: 'user-1',
      );
      await Future<void>.delayed(Duration.zero);

      expect(groupNotifier.state.isAddingMember, isTrue);
      expect(
        groupNotifier.state.isMemberBeingAdded(
          groupId: 'group-1',
          userId: 'user-1',
        ),
        isTrue,
      );
      expect(
        await groupNotifier.addMember(groupId: 'group-1', userId: 'user-1'),
        isFalse,
      );
      expect(repository.addMemberRequests, hasLength(1));

      repository.addMemberCompletion!.complete();
      expect(await firstAdd, isTrue);
      groupNotifier.dispose();
    });

    test(
      'permite agregar otro miembro mientras el primero está en curso',
      () async {
        final repository = _RecordingGroupManagementRepository()
          ..addMemberCompletion = Completer<void>();
        final groupNotifier = notifier(repository);

        final firstAdd = groupNotifier.addMember(
          groupId: 'group-1',
          userId: 'user-1',
        );
        final secondAdd = groupNotifier.addMember(
          groupId: 'group-1',
          userId: 'user-2',
        );
        await Future<void>.delayed(Duration.zero);

        expect(repository.addMemberRequests, hasLength(2));
        expect(
          groupNotifier.state.isMemberBeingAdded(
            groupId: 'group-1',
            userId: 'user-1',
          ),
          isTrue,
        );
        expect(
          groupNotifier.state.isMemberBeingAdded(
            groupId: 'group-1',
            userId: 'user-2',
          ),
          isTrue,
        );

        repository.addMemberCompletion!.complete();
        expect(await firstAdd, isTrue);
        expect(await secondAdd, isTrue);
        groupNotifier.dispose();
      },
    );

    test('mantiene el alta asociada al grupo correcto', () async {
      final repository = _RecordingGroupManagementRepository();
      final groupNotifier = notifier(repository);

      await groupNotifier.addMember(groupId: 'group-1', userId: 'user-1');

      expect(
        groupNotifier.state.isMemberAdded(groupId: 'group-1', userId: 'user-1'),
        isTrue,
      );
      expect(
        groupNotifier.state.isMemberAdded(groupId: 'group-2', userId: 'user-1'),
        isFalse,
      );
      groupNotifier.dispose();
    });
  });
}

class _RecordingGroupManagementRepository implements GroupManagementRepository {
  final List<({String groupId, String userId})> addMemberRequests = [];
  final List<({String groupId, String name})> renameRequests = [];
  final List<String> leaveRequests = [];
  bool shouldFail = false;
  Completer<void>? addMemberCompletion;

  @override
  Future<void> addMember({
    required String groupId,
    required String userId,
  }) async {
    addMemberRequests.add((groupId: groupId, userId: userId));
    await addMemberCompletion?.future;
    if (shouldFail) throw Exception('failure');
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    leaveRequests.add(groupId);
    if (shouldFail) throw Exception('failure');
  }

  @override
  Future<void> renameGroup({
    required String groupId,
    required String name,
  }) async {
    renameRequests.add((groupId: groupId, name: name));
    if (shouldFail) throw Exception('failure');
  }
}
