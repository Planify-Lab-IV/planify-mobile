import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../activity_log/presentation/controllers/activity_log_providers.dart';
import '../controllers/groups_providers.dart';
import '../widgets/group_avatar.dart';
import '../widgets/group_event_tile.dart';
import '../widgets/group_manage_sheet.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final overview = ref.watch(groupsOverviewProvider);
    final selected = ref.watch(selectedGroupOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.navigationGroups,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(unreadCountsProvider);
          ref.invalidate(groupsOverviewProvider);
          // AsyncValue renders refresh failures; the gesture itself completes.
          try {
            await ref.read(groupsOverviewProvider.future);
          } catch (_) {}
        },
        child: CustomScrollView(
          key: const PageStorageKey('groups_scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (overview.isLoading && !overview.hasValue)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    key: Key('groups_screen_loading'),
                  ),
                ),
              )
            else if (overview.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          i18n.groupsLoadError,
                          key: const Key('groups_screen_error'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          key: const Key('groups_screen_retry_button'),
                          onPressed: () =>
                              ref.invalidate(groupsOverviewProvider),
                          child: Text(i18n.retryButton),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (selected == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      i18n.groupsEmpty,
                      key: const Key('groups_screen_empty'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        for (final group in overview.requireValue)
                          GroupAvatar(
                            group: group,
                            selected: group.id == selected.id,
                            onTap: () =>
                                ref
                                        .read(selectedGroupIdProvider.notifier)
                                        .state =
                                    group.id,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                i18n.groupsMembers(selected.memberCount),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          key: const Key('group_manage_button'),
                          tooltip: i18n.groupManageTitle,
                          icon: const Icon(Icons.more_vert_rounded),
                          onPressed: () =>
                              GroupManageSheet.show(context, group: selected),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (!selected.events.any(
                      (event) => !event.status.isCancelled,
                    ))
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            i18n.groupEventsEmpty,
                            key: const Key('group_events_empty'),
                          ),
                        ),
                      ),
                    for (final event in selected.events.where(
                      (event) => !event.status.isCancelled,
                    ))
                      GroupEventTile(event: event),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
