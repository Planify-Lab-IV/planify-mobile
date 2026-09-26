import 'package:flutter/material.dart';

import '../../../../core/formatting/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/event_participant.dart';
import '../../domain/expense_payer_draft.dart';

// Edita los importes de quienes ya fueron seleccionados como pagadores.
// Si solo hay un pagador, no se puede editar el monto
// si hay varios, aparece el campo de ingresar monto
class ExpensePayerAmounts extends StatefulWidget {
  final List<EventParticipant> participants;
  final List<ExpensePayerDraft> payerDrafts;
  final int differenceCents;
  final void Function(String participantId, int? amountCents)
  onPayerAmountChanged;
  final VoidCallback onSplitEvenly;

  const ExpensePayerAmounts({
    super.key,
    required this.participants,
    required this.payerDrafts,
    required this.differenceCents,
    required this.onPayerAmountChanged,
    required this.onSplitEvenly,
  });

  @override
  State<ExpensePayerAmounts> createState() => _ExpensePayerAmountsState();
}

class _ExpensePayerAmountsState extends State<ExpensePayerAmounts> {
  var _splitRevision = 0;

  void _handleSplitEvenly() {
    widget.onSplitEvenly();
    setState(() => _splitRevision++);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payerDrafts.isEmpty) return const SizedBox.shrink();

    final i18n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final isSinglePayer = widget.payerDrafts.length == 1;
    final participantsById = {
      for (final participant in widget.participants)
        participant.id: participant,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.addExpensePayerAmountsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final payer in widget.payerDrafts) ...[
          _ExpensePayerAmountField(
            key: ValueKey('${payer.participantId}-$_splitRevision'),
            participantId: payer.participantId,
            participantName:
                participantsById[payer.participantId]?.username ??
                payer.participantId,
            amountCents: payer.amountCents,
            locale: locale,
            readOnly: isSinglePayer,
            onAmountChanged: (amountCents) =>
                widget.onPayerAmountChanged(payer.participantId, amountCents),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (!isSinglePayer) ...[
          OutlinedButton.icon(
            key: const Key('expense_split_evenly_button'),
            onPressed: _handleSplitEvenly,
            icon: const Icon(Icons.pie_chart_outline_rounded),
            label: Text(i18n.addExpenseSplitEvenly),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (widget.differenceCents != 0)
          Text(
            widget.differenceCents > 0
                ? i18n.addExpenseDifferenceMissing(
                    '\$ ${formatCents(widget.differenceCents, locale: locale)}',
                  )
                : i18n.addExpenseDifferenceExceeded(
                    '\$ ${formatCents(widget.differenceCents.abs(), locale: locale)}',
                  ),
            key: const Key('expense_payer_difference'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _ExpensePayerAmountField extends StatefulWidget {
  final String participantId;
  final String participantName;
  final int amountCents;
  final String locale;
  final bool readOnly;
  final ValueChanged<int?> onAmountChanged;

  const _ExpensePayerAmountField({
    super.key,
    required this.participantId,
    required this.participantName,
    required this.amountCents,
    required this.locale,
    required this.readOnly,
    required this.onAmountChanged,
  });

  @override
  State<_ExpensePayerAmountField> createState() =>
      _ExpensePayerAmountFieldState();
}

class _ExpensePayerAmountFieldState extends State<_ExpensePayerAmountField> {
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
  void didUpdateWidget(covariant _ExpensePayerAmountField oldWidget) {
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
      setState(() => _errorText = i18n.addExpensePayerAmountInvalid);
      widget.onAmountChanged(null);
      return;
    }

    try {
      final amountCents = parseToCents(value);
      if (amountCents < 0) {
        setState(() => _errorText = i18n.addExpensePayerAmountInvalid);
        widget.onAmountChanged(null);
        return;
      }

      _lastEmittedAmountCents = amountCents;
      setState(() => _errorText = null);
      widget.onAmountChanged(amountCents);
    } on FormatException {
      setState(() => _errorText = i18n.addExpensePayerAmountInvalid);
      widget.onAmountChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;

    return TextFormField(
      key: Key('expense_payer_amount_${widget.participantId}'),
      controller: _controller,
      readOnly: widget.readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: i18n.addExpensePayerAmountLabel(widget.participantName),
        prefixText: r'$ ',
        errorText: _errorText,
      ),
      onChanged: widget.readOnly
          ? null
          : (value) => _handleChanged(value, i18n),
    );
  }
}
