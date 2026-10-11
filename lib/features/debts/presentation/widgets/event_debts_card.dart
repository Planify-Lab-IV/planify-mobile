import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/event_participant.dart';
import '../../domain/debt_status.dart';
import '../../domain/event_debt.dart';
import '../controllers/debts_providers.dart';
import '../controllers/event_debts_state.dart';
import '../../domain/debt_settlement.dart';
import 'settle_debt_dialog.dart';
import 'settlement_feedback.dart';

class EventDebtsCard extends ConsumerStatefulWidget {
  final String eventId;
  final String? currentParticipantId;
  final String? eventName;
  final List<EventParticipant> participants;

  const EventDebtsCard({
    super.key,
    required this.eventId,
    this.currentParticipantId,
    this.eventName,
    this.participants = const [],
  });

  @override
  ConsumerState<EventDebtsCard> createState() => _EventDebtsCardState();
}

class _EventDebtsCardState extends ConsumerState<EventDebtsCard> {
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _scheduleFixturePreparation();
  }

  @override
  void didUpdateWidget(covariant EventDebtsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleFixturePreparation();
  }

  void _scheduleFixturePreparation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentParticipantId = widget.currentParticipantId?.trim();
      if (currentParticipantId == null ||
          currentParticipantId.isEmpty ||
          widget.participants.length < 2) {
        return;
      }
      final counterparties = widget.participants.where(
        (participant) => participant.id != currentParticipantId,
      );
      if (counterparties.isEmpty) return;
      final counterparty = counterparties.first;
      final personKey = counterparty.userId?.trim().isNotEmpty == true
          ? 'user:${counterparty.userId!.trim()}'
          : 'participant:${counterparty.id}';
      ref
          .read(eventDebtsNotifierProvider(widget.eventId).notifier)
          .prepareEventFixture(
            eventName: widget.eventName ?? widget.eventId,
            currentParticipantId: currentParticipantId,
            counterpartyParticipantId: counterparty.id,
            counterpartyPersonKey: personKey,
            counterpartyName: counterparty.username,
          );
    });
  }

  Future<void> _confirmAndSettle(EventDebt debt) async {
    final state = ref.read(eventDebtsNotifierProvider(widget.eventId));
    if (_confirming ||
        state.isSettling ||
        state.isRefreshing ||
        !canSettleDebt(debt, widget.currentParticipantId)) {
      return;
    }
    setState(() => _confirming = true);
    final i18n = AppLocalizations.of(context)!;
    final iOwe = widget.currentParticipantId == debt.debtorParticipantId;
    final personName = iOwe ? debt.creditorName : debt.debtorName;
    final amount =
        '\$ ${formatCents(debt.amountCents, locale: Localizations.localeOf(context).toString())}';
    try {
      final confirmed = await SettleDebtDialog.show(
        context,
        personName: personName,
        amount: amount,
        eventName: widget.eventName ?? widget.eventId,
        direction: iOwe
            ? SettleDebtDirection.iOwe
            : SettleDebtDirection.owedToMe,
      );
      if (!mounted || confirmed != true) return;
      final result = await ref
          .read(eventDebtsNotifierProvider(widget.eventId).notifier)
          .settleDebt(debt.id, widget.currentParticipantId);
      if (!mounted) return;
      showSettlementFeedback(ScaffoldMessenger.of(context), i18n, result, () {
        if (mounted) _confirmAndSettle(debt);
      });
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(eventDebtsNotifierProvider(widget.eventId));
    final notifier = ref.read(
      eventDebtsNotifierProvider(widget.eventId).notifier,
    );

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
                  when state.eventDebts.debts.isEmpty =>
                _FeedbackState(
                  key: const Key('event_debts_empty'),
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: AppColors.onSurfaceVariant,
                  message: i18n.eventDebtsEmpty,
                ),
              EventDebtsLoadStatus.success => _DebtList(
                debts: state.eventDebts.debts,
                allSettled: state.eventDebts.allSettled,
                currentParticipantId: widget.currentParticipantId,
                onSettle: _confirmAndSettle,
                isBusy: _confirming || state.isSettling || state.isRefreshing,
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
            Container(
              key: const Key('event_debts_feedback_icon_container'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
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
  final String? currentParticipantId;
  final ValueChanged<EventDebt> onSettle;
  final bool isBusy;

  const _DebtList({
    required this.debts,
    required this.allSettled,
    required this.currentParticipantId,
    required this.onSettle,
    required this.isBusy,
  });

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
          _DebtRow(
            debt: debts[index],
            currentParticipantId: currentParticipantId,
            showAction: canSettleDebt(debts[index], currentParticipantId),
            onSettle: isBusy ? null : () => onSettle(debts[index]),
          ),
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
  final String? currentParticipantId;
  final bool showAction;
  final VoidCallback? onSettle;

  const _DebtRow({
    required this.debt,
    required this.currentParticipantId,
    required this.showAction,
    this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amount = '\$ ${formatCents(debt.amountCents, locale: locale)}';
    final description = switch (currentParticipantId) {
      final participantId when participantId == debt.debtorParticipantId =>
        i18n.eventDebtIOweDescription(debt.creditorName, amount),
      final participantId when participantId == debt.creditorParticipantId =>
        i18n.eventDebtOwedToMeDescription(debt.debtorName, amount),
      _ => i18n.eventDebtDescription(
        debt.debtorName,
        amount,
        debt.creditorName,
      ),
    };
    final status = _debtStatusPresentation(i18n, debt.status);

    return Row(
      key: Key('event_debt_row_${debt.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          status.icon,
          key: Key('event_debt_status_icon_${debt.id}'),
          color: status.color,
          size: 22,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                key: Key('event_debt_description_${debt.id}'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _DebtStatusChip(
                key: Key('event_debt_status_${debt.id}'),
                label: status.label,
                color: status.color,
              ),
              if (showAction) ...[
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  key: Key('settle_debt_button_${debt.id}'),
                  onPressed: onSettle,
                  child: Text(i18n.settleDebtAction),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DebtStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DebtStatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

class _DebtStatusPresentation {
  final String label;
  final Color color;
  final IconData icon;

  const _DebtStatusPresentation({
    required this.label,
    required this.color,
    required this.icon,
  });
}

_DebtStatusPresentation _debtStatusPresentation(
  AppLocalizations i18n,
  DebtStatus status,
) {
  return switch (status) {
    DebtStatus.pending => _DebtStatusPresentation(
      label: i18n.eventDebtPending,
      color: AppColors.warning,
      icon: Icons.schedule_rounded,
    ),
    DebtStatus.settled => _DebtStatusPresentation(
      label: i18n.eventDebtSettled,
      color: AppColors.success,
      icon: Icons.check_circle_rounded,
    ),
  };
}
