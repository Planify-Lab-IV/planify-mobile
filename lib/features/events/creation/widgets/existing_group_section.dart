import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../groups/presentation/controllers/groups_providers.dart';
import '../controllers/event_draft_providers.dart';

class ExistingGroupSection extends ConsumerWidget {
  const ExistingGroupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final draft = ref.watch(eventDraftProvider);
    final myGroupsAsync = ref.watch(myGroupsProvider);

    return myGroupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.outline),
            ),
            child: Text(
              i18n.noGroupsAvailable,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          );
        }

        final groupIds = groups.map((g) => g.id).toSet();
        final validSelectedGroupId = groupIds.contains(draft.selectedGroupId)
            ? draft.selectedGroupId
            : null;

        return FormField<String>(
          key: const Key('select_group_dropdown'),
          initialValue: validSelectedGroupId,
          validator: (_) {
            if (draft.selectedGroupId == null ||
                draft.selectedGroupId!.trim().isEmpty) {
              return i18n.selectGroupRequired;
            }
            return null;
          },
          builder: (fieldState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownMenu<String>(
                  initialSelection: validSelectedGroupId,
                  expandedInsets: EdgeInsets.zero,
                  requestFocusOnTap: false,
                  enableSearch: false,
                  hintText: i18n.selectGroupLabel,
                  trailingIcon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                  ),
                  selectedTrailingIcon: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: AppColors.primary,
                  ),
                  textStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      borderSide: BorderSide(
                        color: fieldState.hasError
                            ? AppColors.error
                            : AppColors.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      borderSide: BorderSide(
                        color: fieldState.hasError
                            ? AppColors.error
                            : AppColors.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      borderSide: BorderSide(
                        color: fieldState.hasError
                            ? AppColors.error
                            : AppColors.outline,
                      ),
                    ),
                  ),
                  menuStyle: MenuStyle(
                    backgroundColor: const WidgetStatePropertyAll(
                      AppColors.surface,
                    ),
                    surfaceTintColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        side: const BorderSide(color: AppColors.outline),
                      ),
                    ),
                    elevation: const WidgetStatePropertyAll(4),
                    maximumSize: const WidgetStatePropertyAll(
                      Size.fromHeight(280),
                    ),
                  ),
                  dropdownMenuEntries: groups.map((group) {
                    return DropdownMenuEntry<String>(
                      value: group.id,
                      label: group.name,
                      trailingIcon: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs + 2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${group.memberCount} ${group.memberCount == 1 ? "miembro" : "miembros"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.darkBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onSelected: (selectedId) {
                    fieldState.didChange(selectedId);
                    if (selectedId != null) {
                      final group = groups.firstWhere(
                        (g) => g.id == selectedId,
                      );
                      ref
                          .read(eventDraftProvider.notifier)
                          .setSelectedGroup(
                            groupId: group.id,
                            groupName: group.name,
                          );
                    }
                  },
                ),
                if (fieldState.hasError) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: Text(
                      fieldState.errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              i18n.loadingGroups,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                i18n.errorLoadingGroups,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref.refresh(myGroupsProvider),
              child: Text(i18n.retryButton),
            ),
          ],
        ),
      ),
    );
  }
}
