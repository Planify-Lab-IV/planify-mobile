import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/groups/data/group_exceptions.dart';
import 'package:planify/features/groups/domain/group_management_repository.dart';
import 'package:planify/features/groups/presentation/controllers/group_management_notifier.dart';
import 'package:planify/features/groups/presentation/controllers/group_management_state.dart';

void main() {
  GroupManagementNotifier notifier(
    _RecordingGroupManagementRepository repository, {
    void Function()? onSuccess,
    void Function()? onUnavailable,
  }) {
    return GroupManagementNotifier(
      repository: repository,
      onGroupManagementSucceeded: onSuccess,
      onGroupManagementUnavailable: onUnavailable,
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
          GroupMemberAdditionResult.added,
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
        GroupMemberAdditionResult.failure,
      );

      expect(
        groupNotifier.state.addMemberStatus,
        GroupManagementActionStatus.error,
      );
      expect(groupNotifier.state.addedMembers, isEmpty);
      expect(successfulActions, isZero);
      groupNotifier.dispose();
    });

    test('refreshes the overview after adding a member is forbidden', () async {
      final repository = _RecordingGroupManagementRepository()
        ..failure = const GroupForbiddenException();
      var unavailableActions = 0;
      var successfulActions = 0;
      final groupNotifier = notifier(
        repository,
        onSuccess: () => successfulActions++,
        onUnavailable: () => unavailableActions++,
      );

      expect(
        await groupNotifier.addMember(groupId: 'group-1', userId: 'user-1'),
        GroupMemberAdditionResult.unavailable,
      );
      expect(
        groupNotifier.state.addMemberStatus,
        GroupManagementActionStatus.error,
      );
      expect(unavailableActions, 1);
      expect(successfulActions, isZero);
      groupNotifier.dispose();
    });

    test(
      'refreshes the overview after renaming a group is forbidden',
      () async {
        final repository = _RecordingGroupManagementRepository()
          ..failure = const GroupForbiddenException();
        var unavailableActions = 0;
        final groupNotifier = notifier(
          repository,
          onUnavailable: () => unavailableActions++,
        );

        expect(
          await groupNotifier.renameGroup(groupId: 'group-1', name: 'Familia'),
          isFalse,
        );
        expect(
          groupNotifier.state.renameStatus,
          GroupManagementActionStatus.error,
        );
        expect(
          groupNotifier.state.renameErrorReason,
          GroupManagementErrorReason.unavailable,
        );
        expect(unavailableActions, 1);
        groupNotifier.dispose();
      },
    );

    test('refreshes the overview after leaving a group is forbidden', () async {
      final repository = _RecordingGroupManagementRepository()
        ..failure = const GroupForbiddenException();
      var unavailableActions = 0;
      final groupNotifier = notifier(
        repository,
        onUnavailable: () => unavailableActions++,
      );

      expect(await groupNotifier.leaveGroup('group-1'), isFalse);
      expect(
        groupNotifier.state.leaveStatus,
        GroupManagementActionStatus.error,
      );
      expect(
        groupNotifier.state.leaveErrorReason,
        GroupManagementErrorReason.unavailable,
      );
      expect(unavailableActions, 1);
      groupNotifier.dispose();
    });

    test('refreshes the overview after a group is no longer found', () async {
      final repository = _RecordingGroupManagementRepository()
        ..failure = const GroupNotFoundException();
      var unavailableActions = 0;
      final groupNotifier = notifier(
        repository,
        onUnavailable: () => unavailableActions++,
      );

      expect(
        await groupNotifier.addMember(groupId: 'group-1', userId: 'user-1'),
        GroupMemberAdditionResult.unavailable,
      );
      expect(
        await groupNotifier.renameGroup(groupId: 'group-1', name: 'Familia'),
        isFalse,
      );
      expect(await groupNotifier.leaveGroup('group-1'), isFalse);
      expect(
        groupNotifier.state.renameErrorReason,
        GroupManagementErrorReason.unavailable,
      );
      expect(
        groupNotifier.state.leaveErrorReason,
        GroupManagementErrorReason.unavailable,
      );
      expect(unavailableActions, 3);
      groupNotifier.dispose();
    });

    test('rejects invalid mutations before reaching the repository', () async {
      final repository = _RecordingGroupManagementRepository();
      final groupNotifier = notifier(repository);

      expect(
        await groupNotifier.addMember(groupId: ' ', userId: 'user-1'),
        GroupMemberAdditionResult.ignored,
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
        GroupMemberAdditionResult.ignored,
      );
      expect(repository.addMemberRequests, hasLength(1));

      repository.addMemberCompletion!.complete();
      expect(await firstAdd, GroupMemberAdditionResult.added);
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
        expect(await firstAdd, GroupMemberAdditionResult.added);
        expect(await secondAdd, GroupMemberAdditionResult.added);
        groupNotifier.dispose();
      },
    );

    test('returns the result associated with each concurrent member', () async {
      final firstMember = (groupId: 'group-1', userId: 'user-1');
      final secondMember = (groupId: 'group-1', userId: 'user-2');
      final firstCompletion = Completer<void>();
      final secondCompletion = Completer<void>();
      final repository = _RecordingGroupManagementRepository()
        ..addMemberCompletions = {
          firstMember: firstCompletion,
          secondMember: secondCompletion,
        }
        ..addMemberFailures = {
          firstMember: const GroupForbiddenException(),
          secondMember: Exception('failure'),
        };
      final groupNotifier = notifier(repository);

      final firstAdd = groupNotifier.addMember(
        groupId: firstMember.groupId,
        userId: firstMember.userId,
      );
      final secondAdd = groupNotifier.addMember(
        groupId: secondMember.groupId,
        userId: secondMember.userId,
      );
      await Future<void>.delayed(Duration.zero);

      firstCompletion.complete();
      await Future<void>.delayed(Duration.zero);
      secondCompletion.complete();

      expect(await firstAdd, GroupMemberAdditionResult.unavailable);
      expect(await secondAdd, GroupMemberAdditionResult.failure);
      groupNotifier.dispose();
    });

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
  Object? failure;
  Completer<void>? addMemberCompletion;
  Map<GroupMemberKey, Completer<void>>? addMemberCompletions;
  Map<GroupMemberKey, Object>? addMemberFailures;

  @override
  Future<void> addMember({
    required String groupId,
    required String userId,
  }) async {
    final member = (groupId: groupId, userId: userId);
    addMemberRequests.add(member);
    await (addMemberCompletions?[member]?.future ??
        addMemberCompletion?.future);
    final memberFailure = addMemberFailures?[member];
    if (memberFailure != null) throw memberFailure;
    if (failure != null) throw failure!;
    if (shouldFail) throw Exception('failure');
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    leaveRequests.add(groupId);
    if (failure != null) throw failure!;
    if (shouldFail) throw Exception('failure');
  }

  @override
  Future<void> renameGroup({
    required String groupId,
    required String name,
  }) async {
    renameRequests.add((groupId: groupId, name: name));
    if (failure != null) throw failure!;
    if (shouldFail) throw Exception('failure');
  }
}
