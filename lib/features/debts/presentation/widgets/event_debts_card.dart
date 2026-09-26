import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/debt_status.dart';
import '../../domain/event_debt.dart';
import '../controllers/debts_providers.dart';
import '../controllers/event_debts_state.dart';

class EventDebtsCard extends ConsumerWidget {
  final String eventId;

  const EventDebtsCard({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(eventDebtsNotifierProvider(eventId));
    final notifier = ref.read(eventDebtsNotifierProvider(eventId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.eventDebtsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          key: const Key('event_debts_card'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: switch (state.loadStatus) {
              EventDebtsLoadStatus.loading => _LoadingState(
                label: i18n.eventDebtsLoading,
              ),
              EventDebtsLoadStatus.error => _FeedbackState(
                key: const Key('event_debts_error'),
                icon: Icons.error_outline_rounded,
                iconColor: AppColors.error,
                message: i18n.eventDebtsLoadError,
                action: TextButton(
                  key: const Key('event_debts_retry_button'),
                  onPressed: notifier.reload,
                  child: Text(i18n.retryButton),
                ),
              ),
              EventDebtsLoadStatus.success
                  when state.eventDebts.debts.isEmpty => _FeedbackState(
                    key: const Key('event_debts_empty'),
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.onSurfaceVariant,
                    message: i18n.eventDebtsEmpty,
                  ),
              EventDebtsLoadStatus.success => _DebtList(
                debts: state.eventDebts.debts,
                allSettled: state.eventDebts.allSettled,
              ),
            },
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  final String label;

  const _LoadingState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('event_debts_loading'),
      label: label,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _FeedbackState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String message;
  final Widget? action;

  const _FeedbackState({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.sm),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _DebtList extends StatelessWidget {
  final List<EventDebt> debts;
  final bool allSettled;

  const _DebtList({required this.debts, required this.allSettled});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (allSettled) ...[
          _AllSettledBadge(label: i18n.eventDebtsAllSettled),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (var index = 0; index < debts.length; index++) ...[
          _DebtRow(debt: debts[index]),
          if (index < debts.length - 1)
            const Divider(height: AppSpacing.lg, color: AppColors.outline),
        ],
      ],
    );
  }
}

class _AllSettledBadge extends StatelessWidget {
  final String label;

  const _AllSettledBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const Key('event_debts_all_settled'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  final EventDebt debt;

  const _DebtRow({required this.debt});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amount = '\$ ${formatCents(debt.amountCents, locale: locale)}';
    final (statusLabel, statusColor) = switch (debt.status) {
      DebtStatus.pending => (i18n.eventDebtPending, AppColors.warning),
      DebtStatus.settled => (i18n.eventDebtSettled, AppColors.success),
    };

    return Row(
      key: Key('event_debt_row_${debt.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            i18n.eventDebtDescription(
              debt.debtorName,
              amount,
              debt.creditorName,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          key: Key('event_debt_status_${debt.id}'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            statusLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // PLANIFY-76 agregará aquí la acción para saldar esta deuda.
      ],
    );
  }
}
