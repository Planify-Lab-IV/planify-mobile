import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/core/widgets/person_row.dart';
import 'package:planify/features/friends/data/fake_friends_repository.dart';
import 'package:planify/features/friends/domain/person.dart';
import 'package:planify/features/friends/presentation/controllers/friends_providers.dart';
import 'package:planify/features/friends/presentation/screens/friends_screen.dart';
import 'package:planify/features/groups/data/fake_group_management_repository.dart';
import 'package:planify/features/groups/data/fake_groups_overview_repository.dart';
import 'package:planify/features/groups/domain/group_management_repository.dart';
import 'package:planify/features/groups/domain/group_overview.dart';
import 'package:planify/features/groups/presentation/controllers/groups_providers.dart';
import 'package:planify/features/groups/presentation/widgets/group_manage_sheet.dart';
import 'package:planify/l10n/app_localizations.dart';

final _group = GroupOverview(
  id: 'group-1',
  name: 'Amigos',
  memberCount: 2,
  events: [],
);

const _friend = Person(
  id: 'friend-1',
  name: 'Ana Pérez',
  username: 'ana',
  relationship: FriendRelationship.friend,
);

Widget app({
  required FakeFriendsRepository friendsRepository,
  required GroupManagementRepository managementRepository,
}) {
  return ProviderScope(
    overrides: [
      friendsRepositoryProvider.overrideWithValue(friendsRepository),
      groupManagementRepositoryProvider.overrideWithValue(managementRepository),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => GroupManageSheet.show(context, group: _group),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

FakeGroupManagementRepository managementRepository(
  FakeGroupsOverviewRepository overview,
) {
  return FakeGroupManagementRepository(
    overviewRepository: overview,
    delay: Duration.zero,
  );
}

Future<void> openSelector(WidgetTester tester) async {
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('group_manage_add_member')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra amigos con PersonRow y permite agregarlos', (
    tester,
  ) async {
    final overview = FakeGroupsOverviewRepository(
      delay: Duration.zero,
      initialGroups: [_group],
    );
    await tester.pumpWidget(
      app(
        friendsRepository: FakeFriendsRepository(
          delay: Duration.zero,
          searchablePeople: const [_friend],
          initialReceivedRequests: const [],
          initialSentRequests: const [],
          initialFriends: const [_friend],
        ),
        managementRepository: managementRepository(overview),
      ),
    );

    await openSelector(tester);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byKey(const Key('group_member_selector_back')), findsOneWidget);
    expect(find.byType(PersonRow), findsOneWidget);
    expect(find.text('Ana Pérez'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('group_member_search_input')),
      'nadie',
    );
    await tester.pump();
    expect(
      find.byKey(const Key('group_member_selector_no_results')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('group_member_search_input')),
      'ana',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('group_member_add_button_friend-1')));
    await tester.pumpAndSettle();

    expect(find.text('Added'), findsOneWidget);
    expect((await overview.getMyGroupsOverview()).single.memberCount, 3);

    await tester.tap(find.byKey(const Key('group_member_selector_back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group_manage_rename')), findsOneWidget);
  });

  testWidgets('explica cómo destrabarse cuando no hay amigos', (tester) async {
    final overview = FakeGroupsOverviewRepository(
      delay: Duration.zero,
      initialGroups: [_group],
    );
    await tester.pumpWidget(
      app(
        friendsRepository: FakeFriendsRepository(
          delay: Duration.zero,
          searchablePeople: const [],
          initialReceivedRequests: const [],
          initialSentRequests: const [],
          initialFriends: const [],
        ),
        managementRepository: managementRepository(overview),
      ),
    );

    await openSelector(tester);

    expect(
      find.byKey(const Key('group_member_selector_empty')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('group_member_selector_go_to_friends')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FriendsScreen), findsOneWidget);
  });

  testWidgets('muestra un reintento si no puede cargar amigos', (tester) async {
    final overview = FakeGroupsOverviewRepository(
      delay: Duration.zero,
      initialGroups: [_group],
    );
    await tester.pumpWidget(
      app(
        friendsRepository: FakeFriendsRepository(
          delay: Duration.zero,
          shouldThrowError: true,
        ),
        managementRepository: managementRepository(overview),
      ),
    );

    await openSelector(tester);

    expect(
      find.byKey(const Key('group_member_selector_error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('group_member_selector_retry')),
      findsOneWidget,
    );
  });
}
