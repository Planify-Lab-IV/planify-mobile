import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/unread_badge.dart';
import '../../../activity_log/presentation/controllers/activity_log_providers.dart';
import '../../domain/group_overview.dart';

class GroupAvatar extends ConsumerWidget {
  final GroupOverview group;
  final bool selected;
  final VoidCallback onTap;

  const GroupAvatar({
    super.key,
    required this.group,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(unreadCountsProvider).asData?.value;
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: group.name,
      child: InkWell(
        key: Key('group_avatar_${group.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: SizedBox(
            width: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primaryContainer,
                      child: Text(
                        InitialsAvatar.initialsFor(group.name),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: selected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (counts != null && counts.forGroup(group.id) > 0)
                      Positioned(
                        top: 0,
                        right: -4,
                        child: UnreadBadge(
                          key: Key('group_unread_badge_${group.id}'),
                          count: counts.forGroup(group.id),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  group.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
