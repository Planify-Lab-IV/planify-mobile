import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class GroupModeAccordionTile extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget child;

  const GroupModeAccordionTile({
    super.key,
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.outline,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurface,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isSelected) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.outline, height: 1),
                const SizedBox(height: AppSpacing.md),
                child,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
