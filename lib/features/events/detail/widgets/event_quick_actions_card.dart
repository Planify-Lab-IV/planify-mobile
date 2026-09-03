import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

class EventQuickActionsCard extends StatelessWidget {
  final bool isCancelled;

  const EventQuickActionsCard({super.key, this.isCancelled = false});

  void _handleActionTap(BuildContext context, String actionLabel) {
    if (isCancelled) return;

    final i18n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(i18n.featureUnderDevelopment),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.quickActionsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  context,
                  key: const Key('quick_action_invite'),
                  icon: Icons.person_add_outlined,
                  label: i18n.quickActionInvite,
                ),
                _buildActionButton(
                  context,
                  key: const Key('quick_action_add_expense'),
                  icon: Icons.receipt_long_outlined,
                  label: i18n.quickActionAddExpense,
                ),
                _buildActionButton(
                  context,
                  key: const Key('quick_action_add_task'),
                  icon: Icons.add_task_outlined,
                  label: i18n.quickActionAddTask,
                ),
                _buildActionButton(
                  context,
                  key: const Key('quick_action_settle'),
                  icon: Icons.account_balance_wallet_outlined,
                  label: i18n.quickActionSettle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isEnabled = !isCancelled;
    final iconColor = isEnabled
        ? theme.colorScheme.primary
        : AppColors.onSurfaceVariant.withValues(alpha: 0.5);
    final textColor = isEnabled
        ? AppColors.onSurface
        : AppColors.onSurfaceVariant.withValues(alpha: 0.5);
    final bgColor = isEnabled
        ? AppColors.lightBlue
        : AppColors.outline.withValues(alpha: 0.3);

    return Expanded(
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: isEnabled ? () => _handleActionTap(context, label) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
