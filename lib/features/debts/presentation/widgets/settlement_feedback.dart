import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/debt_settlement.dart';

void showSettlementFeedback(
  ScaffoldMessengerState messenger,
  AppLocalizations i18n,
  DebtSettlementResult result,
  VoidCallback onRetry,
) {
  if (result == DebtSettlementResult.ignored ||
      result == DebtSettlementResult.alreadySettled) {
    return;
  }
  final success = result == DebtSettlementResult.success;
  final message = switch (result) {
    DebtSettlementResult.success => i18n.settleSuccess,
    DebtSettlementResult.forbidden => i18n.settleForbidden,
    DebtSettlementResult.notFound => i18n.settleNotFound,
    DebtSettlementResult.networkError => i18n.settleNetworkError,
    _ => i18n.settleError,
  };
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      key: Key(success ? 'settle_success_snackbar' : 'settle_error_snackbar'),
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: success ? AppColors.success : AppColors.error,
      action:
          result == DebtSettlementResult.networkError ||
              result == DebtSettlementResult.failure
          ? SnackBarAction(
              label: i18n.retryButton,
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    ),
  );
}
