import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/group_overview.dart';

class GroupManageSheet extends StatelessWidget {
  final GroupOverview group;
  final VoidCallback? onAddMember;
  final VoidCallback? onRename;
  final VoidCallback? onLeave;

  const GroupManageSheet({
    super.key,
    required this.group,
    this.onAddMember,
    this.onRename,
    this.onLeave,
  });

  static Future<void> show(
    BuildContext context, {
    required GroupOverview group,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => GroupManageSheet(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              i18n.groupManageTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              group.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              key: const Key('group_manage_add_member'),
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: Text(i18n.groupManageAddMember),
              onTap: onAddMember,
            ),
            ListTile(
              key: const Key('group_manage_rename'),
              leading: const Icon(Icons.edit_outlined),
              title: Text(i18n.groupManageRename),
              onTap: onRename,
            ),
            ListTile(
              key: const Key('group_manage_leave'),
              leading: Icon(
                Icons.logout_rounded,
                color: theme.colorScheme.error,
              ),
              title: Text(
                i18n.groupManageLeave,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: onLeave,
            ),
          ],
        ),
      ),
    );
  }
}
