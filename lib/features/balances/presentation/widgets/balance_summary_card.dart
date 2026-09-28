import 'package:flutter/material.dart';

import '../../../../core/formatting/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/balance_summary.dart';

class BalanceSummaryCard extends StatelessWidget {
  final BalanceSummary summary;

  const BalanceSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return Row(
      key: const Key('balance_summary_card'),
      children: [
        Expanded(
          child: _SummaryAmount(
            key: const Key('balance_owed_to_me'),
            label: i18n.balancesOwedToMe,
            amount: formatCents(summary.owedToMeCents, locale: locale),
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryAmount(
            key: const Key('balance_i_owe'),
            label: i18n.balancesIOwe,
            amount: formatCents(summary.iOweCents, locale: locale),
            color: AppColors.danger,
          ),
        ),
      ],
    );
  }
}

class _SummaryAmount extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _SummaryAmount({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card.filled(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '\$ $amount',
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
