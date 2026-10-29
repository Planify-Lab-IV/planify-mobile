import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/person_row.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../friends/domain/person.dart';
import '../../../friends/presentation/controllers/friends_providers.dart';
import '../../../friends/presentation/screens/friends_screen.dart';
import '../../domain/group_overview.dart';
import '../controllers/groups_providers.dart';

class GroupAddMemberSheet extends ConsumerStatefulWidget {
  final GroupOverview group;
  final VoidCallback onBack;

  const GroupAddMemberSheet({
    super.key,
    required this.group,
    required this.onBack,
  });

  @override
  ConsumerState<GroupAddMemberSheet> createState() =>
      _GroupAddMemberSheetState();
}

class _GroupAddMemberSheetState extends ConsumerState<GroupAddMemberSheet> {
  final _sheetMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late Future<List<Person>> _friends;
  var _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _friends = _loadFriends();
  }

  Future<List<Person>> _loadFriends() {
    return ref.read(friendsRepositoryProvider).getFriends();
  }

  void _retry() {
    final friends = _loadFriends();
    setState(() {
      _friends = friends;
    });
  }

  Future<void> _goToFriends() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const FriendsScreen()));
    if (!mounted) return;
    _retry();
  }

  List<Person> _filterFriends(List<Person> friends) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return friends;
    return friends
        .where(
          (friend) =>
              friend.name.toLowerCase().contains(query) ||
              friend.username.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  Future<void> _addMember(Person person) async {
    final added = await ref
        .read(groupManagementNotifierProvider.notifier)
        .addMember(groupId: widget.group.id, userId: person.id);
    if (!mounted) return;

    final message = added
        ? AppLocalizations.of(context)!.groupManageMemberAdded
        : AppLocalizations.of(context)!.groupManageActionError;
    final messenger = _sheetMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final managementState = ref.watch(groupManagementNotifierProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: SizedBox(
          height: 440,
          child: ScaffoldMessenger(
            key: _sheetMessengerKey,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SelectorHeader(
                    title: i18n.groupManageAddMember,
                    onBack: widget.onBack,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: FutureBuilder<List<Person>>(
                      future: _friends,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.xl),
                              child: CircularProgressIndicator(
                                key: Key('group_member_selector_loading'),
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return _LoadError(
                            message: i18n.groupManageFriendsLoadError,
                            retryLabel: i18n.retryButton,
                            onRetry: _retry,
                          );
                        }

                        final friends = snapshot.data ?? const <Person>[];
                        if (friends.isEmpty) {
                          return _EmptyFriends(
                            message: i18n.groupManageNoFriends,
                            actionLabel: i18n.groupManageGoToFriends,
                            onGoToFriends: _goToFriends,
                          );
                        }

                        final filteredFriends = _filterFriends(friends);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              key: const Key('group_member_search_input'),
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                labelText: i18n.groupManageSearchFriends,
                                hintText: i18n.friendsSearchHint,
                                prefixIcon: const Icon(Icons.search_rounded),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Expanded(
                              child: filteredFriends.isEmpty
                                  ? _NoFriendResults(
                                      message: i18n.groupManageSearchEmpty,
                                    )
                                  : ListView.builder(
                                      itemCount: filteredFriends.length,
                                      itemBuilder: (context, index) {
                                        final friend = filteredFriends[index];
                                        final wasAdded = managementState
                                            .isMemberAdded(
                                              groupId: widget.group.id,
                                              userId: friend.id,
                                            );
                                        return PersonRow(
                                          person: friend,
                                          trailing: wasAdded
                                              ? Text(
                                                  i18n.groupManageMemberAddedLabel,
                                                )
                                              : FilledButton(
                                                  key: Key(
                                                    'group_member_add_button_${friend.id}',
                                                  ),
                                                  onPressed:
                                                      managementState
                                                          .isMemberBeingAdded(
                                                            groupId:
                                                                widget.group.id,
                                                            userId: friend.id,
                                                          )
                                                      ? null
                                                      : () =>
                                                            _addMember(friend),
                                                  child: Text(
                                                    i18n.groupManageAddMember,
                                                  ),
                                                ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _SelectorHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: const Key('group_member_selector_back'),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _NoFriendResults extends StatelessWidget {
  final String message;

  const _NoFriendResults({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          message,
          key: const Key('group_member_selector_no_results'),
          maxLines: 2,
          softWrap: false,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _LoadError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        key: const Key('group_member_selector_error'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            key: const Key('group_member_selector_retry'),
            onPressed: onRetry,
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onGoToFriends;

  const _EmptyFriends({
    required this.message,
    required this.actionLabel,
    required this.onGoToFriends,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        key: const Key('group_member_selector_empty'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            key: const Key('group_member_selector_go_to_friends'),
            onPressed: onGoToFriends,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
