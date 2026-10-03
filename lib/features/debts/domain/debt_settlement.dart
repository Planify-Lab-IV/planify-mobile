import 'event_debt.dart';

bool canSettleDebt(EventDebt debt, String? participantId) =>
    debt.status.isPending &&
    participantId != null &&
    participantId.trim().isNotEmpty &&
    (debt.debtorParticipantId == participantId ||
        debt.creditorParticipantId == participantId);

enum DebtSettlementResult {
  success,
  alreadySettled,
  forbidden,
  notFound,
  networkError,
  failure,
  ignored;

  bool get succeeded => this == success || this == alreadySettled;
}

sealed class DebtException implements Exception {
  const DebtException();
}

class DebtAlreadySettledException extends DebtException {
  const DebtAlreadySettledException();
}

class DebtAuthorizationException extends DebtException {
  const DebtAuthorizationException();
}

class DebtNotFoundException extends DebtException {
  const DebtNotFoundException();
}

class DebtNetworkException extends DebtException {
  const DebtNetworkException();
}

DebtSettlementResult settlementError(Object error) => switch (error) {
  DebtAlreadySettledException() => DebtSettlementResult.alreadySettled,
  DebtAuthorizationException() => DebtSettlementResult.forbidden,
  DebtNotFoundException() => DebtSettlementResult.notFound,
  DebtNetworkException() => DebtSettlementResult.networkError,
  _ => DebtSettlementResult.failure,
};
