import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/group_overview.dart';
import '../controllers/group_management_state.dart';
import '../controllers/groups_providers.dart';
import 'group_add_member_sheet.dart';

class GroupManageSheet extends StatefulWidget {
  final GroupOverview group;

  const GroupManageSheet({super.key, required this.group});

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

  Future<void> _renameGroup() async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await GroupRenameDialog.show(navigator.context, group: widget.group);
  }

  Future<void> _leaveGroup() async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await GroupLeaveConfirmationDialog.show(
      navigator.context,
      group: widget.group,
    );
  }

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
              onTap: _renameGroup,
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
              onTap: _leaveGroup,
            ),
          ],
        ),
      ),
    );
  }
}

class GroupRenameDialog extends ConsumerStatefulWidget {
  final GroupOverview group;

  const GroupRenameDialog({super.key, required this.group});

  static Future<bool?> show(
    BuildContext context, {
    required GroupOverview group,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => GroupRenameDialog(group: group),
    );
  }

  @override
  ConsumerState<GroupRenameDialog> createState() => _GroupRenameDialogState();
}

class _GroupRenameDialogState extends ConsumerState<GroupRenameDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final name = _nameController.text.trim();
    return name.isNotEmpty &&
        name.length <= 80 &&
        name != widget.group.name.trim();
  }

  Future<void> _submit() async {
    if (!_canSave) return;
    final renamed = await ref
        .read(groupManagementNotifierProvider.notifier)
        .renameGroup(groupId: widget.group.id, name: _nameController.text);
    if (mounted && renamed) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final managementState = ref.watch(groupManagementNotifierProvider);
    final isLoading = managementState.isRenaming;

    return AlertDialog(
      title: Text(i18n.groupRenameDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('group_rename_field'),
            controller: _nameController,
            autofocus: true,
            enabled: !isLoading,
            maxLength: 80,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(labelText: i18n.groupRenameFieldLabel),
          ),
          if (managementState.renameStatus == GroupManagementActionStatus.error)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                i18n.groupRenameError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(i18n.cancelButton),
        ),
        FilledButton(
          key: const Key('group_rename_save_button'),
          onPressed: isLoading || !_canSave ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(i18n.groupRenameSave),
        ),
      ],
    );
  }
}

class GroupLeaveConfirmationDialog extends ConsumerWidget {
  final GroupOverview group;

  const GroupLeaveConfirmationDialog({super.key, required this.group});

  static Future<bool?> show(
    BuildContext context, {
    required GroupOverview group,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => GroupLeaveConfirmationDialog(group: group),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final left = await ref
        .read(groupManagementNotifierProvider.notifier)
        .leaveGroup(group.id);
    if (context.mounted && left) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final managementState = ref.watch(groupManagementNotifierProvider);
    final isLoading = managementState.isLeaving;

    return AlertDialog(
      title: Text(i18n.groupLeaveDialogTitle(group.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(i18n.groupLeaveDialogDescription),
          if (managementState.leaveStatus == GroupManagementActionStatus.error)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                i18n.groupLeaveError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(i18n.cancelButton),
        ),
        FilledButton(
          key: const Key('group_leave_confirm_button'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: isLoading ? null : () => _confirm(context, ref),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(i18n.groupManageLeave),
        ),
      ],
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
