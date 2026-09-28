import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../events/detail/screens/event_detail_screen.dart';
import '../../domain/balance_direction.dart';
import '../../domain/event_balance_line.dart';
import '../../domain/person_balance_detail.dart';
import '../../domain/person_balance_status.dart';
import '../controllers/balances_providers.dart';
import '../controllers/person_balance_detail_state.dart';

class PersonBalanceDetailSheet extends ConsumerWidget {
  final String personKey;

  const PersonBalanceDetailSheet({super.key, required this.personKey});

  static Future<void> show(BuildContext context, String personKey) async {
    final eventId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => PersonBalanceDetailSheet(personKey: personKey),
    );

    if (eventId == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventDetailScreen(eventId: eventId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(personBalanceDetailNotifierProvider(personKey));
    final notifier = ref.read(
      personBalanceDetailNotifierProvider(personKey).notifier,
    );

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: switch (state.loadStatus) {
          PersonBalanceDetailLoadStatus.loading => const _LoadingContent(),
          PersonBalanceDetailLoadStatus.error => _ErrorContent(
            onRetry: notifier.reload,
          ),
          PersonBalanceDetailLoadStatus.success => _DetailContent(
            detail: state.detail!,
          ),
        },
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        key: const Key('person_balance_detail_loading'),
        label: 'Cargando detalle de saldo',
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorContent({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No se pudo cargar el detalle del saldo.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const Key('person_balance_detail_retry_button'),
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final PersonBalanceDetail detail;

  const _DetailContent({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      key: const Key('person_balance_detail_background'),
      color: AppColors.background,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            key: const Key('person_balance_detail_sheet'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NetHeader(detail: detail),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Desglose por evento',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final line in detail.breakdown) ...[
                  _EventBalanceLineRow(detail: detail, line: line),
                  const SizedBox(height: AppSpacing.sm),
                ],
                // PLANIFY-76: insertar aquí la acción “Saldar todo”.
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NetHeader extends StatelessWidget {
  final PersonBalanceDetail detail;

  const _NetHeader({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amount = formatCents(detail.netCents.abs(), locale: locale);
    final header = switch (detail.status) {
      PersonBalanceStatus.pay => (
        color: AppColors.danger,
        text: 'Le debés \$ $amount a ${detail.displayName}',
        icon: Icons.arrow_downward_rounded,
      ),
      PersonBalanceStatus.pending => (
        color: AppColors.success,
        text: '${detail.displayName} te debe \$ $amount',
        icon: Icons.arrow_upward_rounded,
      ),
      PersonBalanceStatus.settled => (
        color: AppColors.onSurfaceVariant,
        text: 'Están a mano',
        icon: Icons.handshake_outlined,
      ),
    };

    return Column(
      children: [
        Icon(header.icon, color: header.color, size: 32),
        const SizedBox(height: AppSpacing.sm),
        Text(
          header.text,
          key: const Key('person_balance_detail_net_label'),
          style: theme.textTheme.titleLarge?.copyWith(
            color: header.color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '\$ $amount',
          key: const Key('person_balance_detail_net_amount'),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: header.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _EventBalanceLineRow extends StatelessWidget {
  final PersonBalanceDetail detail;
  final EventBalanceLine line;

  const _EventBalanceLineRow({required this.detail, required this.line});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final direction = switch (line.direction) {
      BalanceDirection.iOwe => (
        color: AppColors.danger,
        icon: Icons.arrow_downward_rounded,
        text: 'Le debés a ${detail.displayName}',
      ),
      BalanceDirection.owedToMe => (
        color: AppColors.success,
        icon: Icons.arrow_upward_rounded,
        text: '${detail.displayName} te debe',
      ),
    };

    return Card.filled(
      color: AppColors.surface,
      elevation: 2,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      child: InkWell(
        key: Key('person_balance_detail_line_${line.eventId}'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => Navigator.of(context).pop(line.eventId),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(direction.icon, color: direction.color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.eventName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      direction.text,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: direction.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '\$ ${formatCents(line.amountCents.abs(), locale: locale)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: direction.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
