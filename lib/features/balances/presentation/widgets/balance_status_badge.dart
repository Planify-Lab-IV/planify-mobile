import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/person_balance_status.dart';

class BalanceStatusBadge extends StatelessWidget {
  final PersonBalanceStatus status;

  const BalanceStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      PersonBalanceStatus.pay => (i18n.balanceStatusPay, AppColors.danger),
      PersonBalanceStatus.pending => (
        i18n.balanceStatusPending,
        AppColors.warning,
      ),
      PersonBalanceStatus.settled => (
        i18n.balanceStatusSettled,
        AppColors.success,
      ),
    };

    return Container(
      key: Key('balance_status_${status.name}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
