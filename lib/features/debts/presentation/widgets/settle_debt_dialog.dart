import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

enum SettleDebtDirection { iOwe, owedToMe }

class SettleDebtDialog extends StatelessWidget {
  final String personName;
  final String? amount;
  final String? eventName;
  final SettleDebtDirection? direction;

  const SettleDebtDialog({
    super.key,
    required this.personName,
    this.amount,
    this.eventName,
    this.direction,
  }) : assert(
         amount == null || direction != null,
         'A punctual settlement requires its debt direction.',
       );

  bool get isAll => amount == null;

  static Future<bool?> show(
    BuildContext context, {
    required String personName,
    String? amount,
    String? eventName,
    SettleDebtDirection? direction,
  }) => showDialog<bool>(
    context: context,
    builder: (_) => SettleDebtDialog(
      personName: personName,
      amount: amount,
      eventName: eventName,
      direction: direction,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final prefix = isAll ? 'settle_all_dialog' : 'settle_debt_dialog';
    return AlertDialog(
      key: Key(prefix),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      icon: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.error,
          size: 36,
        ),
      ),
      title: Text(
        isAll ? i18n.settleAllDialogTitle : i18n.settleDebtDialogTitle,
      ),
      content: Text(
        isAll
            ? i18n.settleAllDialogMessage(personName)
            : switch (direction!) {
                SettleDebtDirection.iOwe => i18n.settleOwnDebtDialogMessage(
                  personName,
                  amount!,
                  eventName!,
                ),
                SettleDebtDirection.owedToMe =>
                  i18n.settleOwedDebtDialogMessage(
                    personName,
                    amount!,
                    eventName!,
                  ),
              },
      ),
      actions: [
        TextButton(
          key: Key('${prefix}_dismiss_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(i18n.cancelButton),
        ),
        ElevatedButton(
          key: Key('${prefix}_confirm_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 44),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(isAll ? i18n.settleAllAction : i18n.settleDebtAction),
        ),
      ],
    );
  }
}
