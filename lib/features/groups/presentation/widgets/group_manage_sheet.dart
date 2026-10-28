import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/group_overview.dart';
import 'group_add_member_sheet.dart';

class GroupManageSheet extends StatefulWidget {
  final GroupOverview group;
  final VoidCallback? onRename;
  final VoidCallback? onLeave;

  const GroupManageSheet({
    super.key,
    required this.group,
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => GroupManageSheet(group: group),
    );
  }

  @override
  State<GroupManageSheet> createState() => _GroupManageSheetState();
}

class _GroupManageSheetState extends State<GroupManageSheet> {
  var _isAddingMemberExpanded = false;

  void _showMemberSelector() => setState(() => _isAddingMemberExpanded = true);

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isAddingMemberExpanded) {
      return GroupAddMemberSheet(
        group: widget.group,
        onBack: () => setState(() => _isAddingMemberExpanded = false),
      );
    }

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
            _SheetHeader(group: widget.group),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              key: const Key('group_manage_add_member'),
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: Text(i18n.groupManageAddMember),
              onTap: _showMemberSelector,
            ),
            ListTile(
              key: const Key('group_manage_rename'),
              leading: const Icon(Icons.edit_outlined),
              title: Text(i18n.groupManageRename),
              onTap: widget.onRename,
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
              onTap: widget.onLeave,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final GroupOverview group;

  const _SheetHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final i18n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }
}
