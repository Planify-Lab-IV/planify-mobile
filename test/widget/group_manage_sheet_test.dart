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
import 'package:planify/features/groups/presentation/widgets/group_add_member_sheet.dart';
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
  FakeGroupsOverviewRepository overview, {
  bool shouldThrowError = false,
}) {
  return FakeGroupManagementRepository(
    overviewRepository: overview,
    delay: Duration.zero,
    shouldThrowError: shouldThrowError,
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
    await tester.pump();

    expect(find.text('Added'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GroupAddMemberSheet),
        matching: find.text('Member added successfully.'),
      ),
      findsOneWidget,
    );
    expect((await overview.getMyGroupsOverview()).single.memberCount, 3);

    await tester.tap(find.byKey(const Key('group_member_selector_back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group_manage_rename')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await openSelector(tester);
    expect(find.text('Added'), findsOneWidget);
  });

  testWidgets('muestra el error de alta dentro de la hoja', (tester) async {
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
        managementRepository: managementRepository(
          overview,
          shouldThrowError: true,
        ),
      ),
    );

    await openSelector(tester);
    await tester.tap(find.byKey(const Key('group_member_add_button_friend-1')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(GroupAddMemberSheet),
        matching: find.text("We couldn't update the group. Please try again."),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('group_member_add_button_friend-1')),
      findsOneWidget,
    );
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

  testWidgets('renombra solo con un nombre válido y cierra al guardar', (
    tester,
  ) async {
    final overview = FakeGroupsOverviewRepository(
      delay: Duration.zero,
      initialGroups: [_group],
    );
    await tester.pumpWidget(
      app(
        friendsRepository: FakeFriendsRepository(delay: Duration.zero),
        managementRepository: managementRepository(overview),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_manage_rename')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group_manage_add_member')), findsNothing);

    final nameField = find.byKey(const Key('group_rename_field'));
    expect(tester.widget<TextField>(nameField).controller!.text, 'Amigos');
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('group_rename_save_button')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(nameField, 'Familia');
    await tester.pump();
    await tester.tap(find.byKey(const Key('group_rename_save_button')));
    await tester.pumpAndSettle();

    expect((await overview.getMyGroupsOverview()).single.name, 'Familia');
    expect(find.byKey(const Key('group_rename_field')), findsNothing);
  });

  testWidgets('conserva el nombre escrito si renombrar falla', (tester) async {
    final overview = FakeGroupsOverviewRepository(
      delay: Duration.zero,
      initialGroups: [_group],
    );
    await tester.pumpWidget(
      app(
        friendsRepository: FakeFriendsRepository(delay: Duration.zero),
        managementRepository: managementRepository(
          overview,
          shouldThrowError: true,
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_manage_rename')));
    await tester.pumpAndSettle();
    final nameField = find.byKey(const Key('group_rename_field'));
    await tester.enterText(nameField, 'Familia');
    await tester.pump();
    await tester.tap(find.byKey(const Key('group_rename_save_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('group_rename_field')), findsOneWidget);
    expect(tester.widget<TextField>(nameField).controller!.text, 'Familia');
    expect(
      find.text("We couldn't rename the group. Please try again."),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_manage_rename')));
    await tester.pumpAndSettle();

    expect(
      find.text("We couldn't rename the group. Please try again."),
      findsNothing,
    );
  });

  testWidgets('no conserva el error al reabrir abandonar grupo', (
    tester,
  ) async {
    final overview = FakeGroupsOverviewRepository(
      delay: Duration.zero,
      initialGroups: [_group],
    );
    await tester.pumpWidget(
      app(
        friendsRepository: FakeFriendsRepository(delay: Duration.zero),
        managementRepository: managementRepository(
          overview,
          shouldThrowError: true,
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_manage_leave')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_leave_confirm_button')));
    await tester.pumpAndSettle();
    expect(
      find.text("We couldn't leave the group. Please try again."),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_manage_leave')));
    await tester.pumpAndSettle();

    expect(
      find.text("We couldn't leave the group. Please try again."),
      findsNothing,
    );
  });

  testWidgets('permite cancelar o confirmar que abandona un grupo', (
    tester,
  ) async {
    final overview = FakeGroupsOverviewRepository(
      delay: Duration.zero,
      initialGroups: [_group],
    );
    await tester.pumpWidget(
      app(
        friendsRepository: FakeFriendsRepository(delay: Duration.zero),
        managementRepository: managementRepository(overview),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_manage_leave')));
    await tester.pumpAndSettle();
    expect(find.text('Leave Amigos?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group_manage_leave')), findsNothing);

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_manage_leave')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group_leave_confirm_button')));
    await tester.pumpAndSettle();

    expect(await overview.getMyGroupsOverview(), isEmpty);
    expect(find.byKey(const Key('group_manage_leave')), findsNothing);
  });
}
