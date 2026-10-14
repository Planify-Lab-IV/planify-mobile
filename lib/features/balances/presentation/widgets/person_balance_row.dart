import 'package:flutter/material.dart';

import '../../../../core/formatting/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/person_balance.dart';
import '../../domain/person_balance_status.dart';
import 'balance_status_badge.dart';

class PersonBalanceRow extends StatelessWidget {
  final PersonBalance personBalance;
  final ValueChanged<String> onPersonTap;

  const PersonBalanceRow({
    super.key,
    required this.personBalance,
    required this.onPersonTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amount = formatCents(personBalance.netCents.abs(), locale: locale);
    final amountColor = switch (personBalance.status) {
      PersonBalanceStatus.pay => AppColors.danger,
      PersonBalanceStatus.pending => AppColors.warning,
      PersonBalanceStatus.settled => AppColors.success,
    };

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('balance_person_${personBalance.personKey}'),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () => onPersonTap(personBalance.personKey),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personBalance.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      BalanceStatusBadge(status: personBalance.status),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '\$ $amount',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
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
