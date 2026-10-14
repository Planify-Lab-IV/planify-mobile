import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/event_draft_providers.dart';

class NewGroupSection extends ConsumerWidget {
  final TextEditingController groupNameController;
  final TextEditingController memberIdentifierController;
  final VoidCallback onAddMember;

  const NewGroupSection({
    super.key,
    required this.groupNameController,
    required this.memberIdentifierController,
    required this.onAddMember,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final draft = ref.watch(eventDraftProvider);
    final members = draft.newGroupMembers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nombre del nuevo grupo
        Text(
          i18n.newGroupNameLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          key: const Key('new_group_name_input'),
          controller: groupNameController,
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            ref.read(eventDraftProvider.notifier).setNewGroupName(value);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            hintText: i18n.newGroupNameHint,
            prefixIcon: const Icon(
              Icons.group_outlined,
              color: AppColors.primary,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return i18n.newGroupNameRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Entrada de identificadores de miembros
        Text(
          i18n.memberIdentifierLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('member_identifier_input'),
                controller: memberIdentifierController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onAddMember(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  hintText: i18n.memberIdentifierHint,
                  prefixIcon: const Icon(
                    Icons.person_add_alt_1_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              key: const Key('add_member_button'),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                minimumSize: const Size(52, 52),
              ),
              onPressed: onAddMember,
              icon: const Icon(Icons.add_rounded),
              tooltip: i18n.addMemberButton,
            ),
          ],
        ),

        // Lista de chips de miembros agregados
        if (members.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            i18n.membersListTitle(members.length),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: members.map((member) {
              return Chip(
                key: Key('member_chip_$member'),
                avatar: const CircleAvatar(
                  backgroundColor: AppColors.lightBlue,
                  child: Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.darkBlue,
                  ),
                ),
                label: Text(
                  member,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () {
                  ref.read(eventDraftProvider.notifier).removeMember(member);
                },
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
