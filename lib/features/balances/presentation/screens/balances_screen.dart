import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/formatting/money_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/balance_summary.dart';
import '../../domain/person_balance.dart';
import '../../domain/person_balance_status.dart';
import '../controllers/balances_providers.dart';
import '../controllers/balances_state.dart';
import '../widgets/balance_summary_card.dart';
import '../widgets/person_balance_row.dart';

class BalancesScreen extends ConsumerWidget {
  final ValueChanged<String>? onPersonTap;

  const BalancesScreen({super.key, this.onPersonTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final state = ref.watch(balancesNotifierProvider);
    final notifier = ref.read(balancesNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.balancesTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton.filledTonal(
            tooltip: i18n.retryButton,
            onPressed: notifier.reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        top: false,
        child: switch (state.loadStatus) {
          BalancesLoadStatus.loading => _LoadingState(
            label: i18n.balancesLoading,
          ),
          BalancesLoadStatus.error => _FeedbackState(
            key: const Key('balances_error'),
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.error,
            message: i18n.balancesLoadError,
            action: FilledButton(
              key: const Key('balances_retry_button'),
              onPressed: notifier.reload,
              child: Text(i18n.retryButton),
            ),
          ),
          BalancesLoadStatus.success => _BalancesContent(
            state: state,
            onPersonTap: (personKey) => _handlePersonTap(context, personKey),
          ),
        },
      ),
    );
  }

  void _handlePersonTap(BuildContext context, String personKey) {
    if (onPersonTap != null) {
      onPersonTap!(personKey);
      return;
    }

    final i18n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(i18n.featureUnderDevelopment),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

enum _BalanceFilter { all, owedToMe, iOwe }

class _BalancesContent extends StatefulWidget {
  final BalancesState state;
  final ValueChanged<String> onPersonTap;

  const _BalancesContent({required this.state, required this.onPersonTap});

  @override
  State<_BalancesContent> createState() => _BalancesContentState();
}

class _BalancesContentState extends State<_BalancesContent> {
  _BalanceFilter _filter = _BalanceFilter.all;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final people = _filteredPeople(widget.state.people);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BalanceNetHeader(summary: widget.state.summary),
              const SizedBox(height: AppSpacing.lg),
              BalanceSummaryCard(summary: widget.state.summary),
              const SizedBox(height: AppSpacing.lg),
              _BalanceFilterSelector(
                selected: _filter,
                onSelected: (filter) => setState(() => _filter = filter),
                allLabel: i18n.balancesFilterAll,
                owedToMeLabel: i18n.balancesOwedToMe,
                iOweLabel: i18n.balancesIOwe,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                i18n.balancesPeopleTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (widget.state.isEmpty)
                Card(
                  key: const Key('balances_people_card'),
                  child: _FeedbackState(
                    key: const Key('balances_empty'),
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.onSurfaceVariant,
                    message: i18n.balancesEmpty,
                  ),
                )
              else if (people.isEmpty)
                Card(
                  key: const Key('balances_people_card'),
                  child: _FeedbackState(
                    key: const Key('balances_filter_empty'),
                    icon: Icons.filter_list_off_rounded,
                    iconColor: AppColors.onSurfaceVariant,
                    message: i18n.balancesFilterEmpty,
                  ),
                )
              else
                Column(
                  key: const Key('balances_people_card'),
                  children: [
                    for (var index = 0; index < people.length; index++) ...[
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: PersonBalanceRow(
                            personBalance: people[index],
                            onPersonTap: widget.onPersonTap,
                          ),
                        ),
                      ),
                      if (index < people.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<PersonBalance> _filteredPeople(List<PersonBalance> people) {
    // Hasta que BE exponga la dirección de netCents, el fake asocia pending
    // con "Me deben" y pay con "Debo". Los saldos settled se ven en Todo.
    return switch (_filter) {
      _BalanceFilter.all => people,
      _BalanceFilter.owedToMe =>
        people
            .where((person) => person.status == PersonBalanceStatus.pending)
            .toList(),
      _BalanceFilter.iOwe =>
        people
            .where((person) => person.status == PersonBalanceStatus.pay)
            .toList(),
    };
  }
}

class _BalanceFilterSelector extends StatelessWidget {
  final _BalanceFilter selected;
  final ValueChanged<_BalanceFilter> onSelected;
  final String allLabel;
  final String owedToMeLabel;
  final String iOweLabel;

  const _BalanceFilterSelector({
    required this.selected,
    required this.onSelected,
    required this.allLabel,
    required this.owedToMeLabel,
    required this.iOweLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('balance_filter'),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BalanceFilterTab(
              key: const Key('balance_filter_all'),
              label: allLabel,
              isSelected: selected == _BalanceFilter.all,
              onTap: () => onSelected(_BalanceFilter.all),
            ),
          ),
          Expanded(
            child: _BalanceFilterTab(
              key: const Key('balance_filter_owed_to_me'),
              label: owedToMeLabel,
              isSelected: selected == _BalanceFilter.owedToMe,
              onTap: () => onSelected(_BalanceFilter.owedToMe),
            ),
          ),
          Expanded(
            child: _BalanceFilterTab(
              key: const Key('balance_filter_i_owe'),
              label: iOweLabel,
              isSelected: selected == _BalanceFilter.iOwe,
              onTap: () => onSelected(_BalanceFilter.iOwe),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceFilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BalanceFilterTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? AppColors.surface : Colors.transparent,
        elevation: isSelected ? AppDimens.cardElevation : 0,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceNetHeader extends StatelessWidget {
  final BalanceSummary summary;

  const _BalanceNetHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final netCents = summary.owedToMeCents - summary.iOweCents;
    final color = netCents.isNegative ? AppColors.danger : AppColors.success;
    final sign = netCents > 0 ? '+' : '';

    return Column(
      children: [
        Text(
          i18n.balancesNetLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$sign\$ ${formatCents(netCents, locale: locale)}',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
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
      key: const Key('balances_loading'),
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
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
