import 'package:flutter/material.dart';

import '../../../../core/formatting/money_formatter.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

// Captura los datos que inputea el usuario que identifican el gasto y comunica su valor normalizado.
class ExpenseHeaderFields extends StatefulWidget {
  final String initialDescription;
  final String initialTotalAmount;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<int?> onTotalAmountChanged;

  const ExpenseHeaderFields({
    super.key,
    this.initialDescription = '',
    this.initialTotalAmount = '',
    required this.onDescriptionChanged,
    required this.onTotalAmountChanged,
  });

  @override
  State<ExpenseHeaderFields> createState() => _ExpenseHeaderFieldsState();
}

class _ExpenseHeaderFieldsState extends State<ExpenseHeaderFields> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _totalAmountController;
  String? _totalAmountError;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _totalAmountController = TextEditingController(
      text: widget.initialTotalAmount,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  void _handleTotalAmountChanged(String value, AppLocalizations i18n) {
    if (value.trim().isEmpty) {
      setState(() => _totalAmountError = i18n.addExpenseTotalRequired);
      widget.onTotalAmountChanged(null);
      return;
    }

    try {
      final amountCents = parseToCents(value);
      if (amountCents <= 0) {
        setState(() => _totalAmountError = i18n.addExpenseTotalInvalid);
        widget.onTotalAmountChanged(null);
        return;
      }

      setState(() => _totalAmountError = null);
      widget.onTotalAmountChanged(amountCents);
    } on FormatException {
      setState(() => _totalAmountError = i18n.addExpenseTotalInvalid);
      widget.onTotalAmountChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;

    return Column(
      children: [
        TextFormField(
          key: const Key('expense_description_field'),
          controller: _descriptionController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: i18n.addExpenseDescriptionLabel,
            hintText: i18n.addExpenseDescriptionHint,
          ),
          onChanged: widget.onDescriptionChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: const Key('expense_total_field'),
          controller: _totalAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: i18n.addExpenseTotalLabel,
            hintText: i18n.addExpenseTotalHint,
            prefixText: r'$ ',
            errorText: _totalAmountError,
          ),
          onChanged: (value) => _handleTotalAmountChanged(value, i18n),
        ),
      ],
    );
  }
}
