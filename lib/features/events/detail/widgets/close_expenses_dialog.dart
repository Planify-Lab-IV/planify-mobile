import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

class CloseExpensesDialog extends StatelessWidget {
  const CloseExpensesDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const CloseExpensesDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      icon: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_outline_rounded,
          color: AppColors.warning,
          size: 36,
        ),
      ),
      title: Text(
        i18n.closeExpensesDialogTitle,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        i18n.closeExpensesDialogMessage,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          key: const Key('close_expenses_dialog_dismiss_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            i18n.closeExpensesDismiss,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          key: const Key('close_expenses_dialog_confirm_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: AppColors.onWarning,
            minimumSize: const Size(120, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(i18n.closeExpensesConfirm),
        ),
      ],
    );
  }
}
