import 'package:flutter/material.dart';

import '../../../../core/formatting/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/event_participant.dart';
import '../../domain/expense_debtor_draft.dart';

// Edita los importes de quienes ya fueron seleccionados como deudores
class ExpenseDebtorAmounts extends StatefulWidget {
  final List<EventParticipant> participants;
  final List<ExpenseDebtorDraft> debtorDrafts;
  final int differenceCents;
  final void Function(String participantId, int? amountCents)
  onDebtorAmountChanged;
  final VoidCallback onSplitEvenly;

  const ExpenseDebtorAmounts({
    super.key,
    required this.participants,
    required this.debtorDrafts,
    required this.differenceCents,
    required this.onDebtorAmountChanged,
    required this.onSplitEvenly,
  });

  @override
  State<ExpenseDebtorAmounts> createState() => _ExpenseDebtorAmountsState();
}

class _ExpenseDebtorAmountsState extends State<ExpenseDebtorAmounts> {
  var _splitRevision = 0;

  void _handleSplitEvenly() {
    widget.onSplitEvenly();
    setState(() => _splitRevision++);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.debtorDrafts.isEmpty) return const SizedBox.shrink();

    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final isSingleDebtor = widget.debtorDrafts.length == 1;
    final participantsById = {
      for (final participant in widget.participants)
        participant.id: participant,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.addExpenseDebtorAmountsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final debtor in widget.debtorDrafts) ...[
          _ExpenseDebtorAmountField(
            key: ValueKey('${debtor.participantId}-$_splitRevision'),
            participantId: debtor.participantId,
            participantName:
                participantsById[debtor.participantId]?.username ??
                debtor.participantId,
            amountCents: debtor.amountCents,
            locale: locale,
            readOnly: isSingleDebtor,
            onAmountChanged: (amountCents) =>
                widget.onDebtorAmountChanged(debtor.participantId, amountCents),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (!isSingleDebtor) ...[
          OutlinedButton.icon(
            key: const Key('expense_debtor_split_evenly_button'),
            onPressed: _handleSplitEvenly,
            icon: const Icon(Icons.pie_chart_outline_rounded),
            label: Text(i18n.addExpenseSplitDebtorsEvenly),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (widget.differenceCents != 0)
          Text(
            widget.differenceCents > 0
                ? i18n.addExpenseDebtorDifferenceMissing(
                    '\$ ${formatCents(widget.differenceCents, locale: locale)}',
                  )
                : i18n.addExpenseDebtorDifferenceExceeded(
                    '\$ ${formatCents(widget.differenceCents.abs(), locale: locale)}',
                  ),
            key: const Key('expense_debtor_difference'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _ExpenseDebtorAmountField extends StatefulWidget {
  final String participantId;
  final String participantName;
  final int amountCents;
  final String locale;
  final bool readOnly;
  final ValueChanged<int?> onAmountChanged;

  const _ExpenseDebtorAmountField({
    super.key,
    required this.participantId,
    required this.participantName,
    required this.amountCents,
    required this.locale,
    required this.readOnly,
    required this.onAmountChanged,
  });

  @override
  State<_ExpenseDebtorAmountField> createState() =>
      _ExpenseDebtorAmountFieldState();
}

class _ExpenseDebtorAmountFieldState extends State<_ExpenseDebtorAmountField> {
  late final TextEditingController _controller;
  int? _lastEmittedAmountCents;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatCents(widget.amountCents, locale: widget.locale),
    );
  }

  @override
  void didUpdateWidget(covariant _ExpenseDebtorAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amountCents != oldWidget.amountCents &&
        widget.amountCents != _lastEmittedAmountCents) {
      _controller.text = formatCents(widget.amountCents, locale: widget.locale);
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value, AppLocalizations i18n) {
    if (value.trim().isEmpty) {
      setState(() => _errorText = i18n.addExpenseDebtorAmountInvalid);
      widget.onAmountChanged(null);
      return;
    }

    try {
      final amountCents = parseToCents(value);
      if (amountCents < 0) {
        setState(() => _errorText = i18n.addExpenseDebtorAmountInvalid);
        widget.onAmountChanged(null);
        return;
      }

      _lastEmittedAmountCents = amountCents;
      setState(() => _errorText = null);
      widget.onAmountChanged(amountCents);
    } on FormatException {
      setState(() => _errorText = i18n.addExpenseDebtorAmountInvalid);
      widget.onAmountChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;

    return TextFormField(
      key: Key('expense_debtor_amount_${widget.participantId}'),
      controller: _controller,
      readOnly: widget.readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: i18n.addExpenseDebtorAmountLabel(widget.participantName),
        prefixText: r'$ ',
        errorText: _errorText,
      ),
      onChanged: widget.readOnly
          ? null
          : (value) => _handleChanged(value, i18n),
    );
  }
}
