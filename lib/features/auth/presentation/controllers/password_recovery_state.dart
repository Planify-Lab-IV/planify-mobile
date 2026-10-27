enum PasswordRecoveryOperation { request, reset }

enum PasswordRecoveryFailureReason {
  invalidResetCode,
  invalidResetData,
  networkError,
  unknown,
}

sealed class PasswordRecoveryState {
  const PasswordRecoveryState();
}

class PasswordRecoveryIdle extends PasswordRecoveryState {
  const PasswordRecoveryIdle();
}

class PasswordRecoveryLoading extends PasswordRecoveryState {
  final PasswordRecoveryOperation operation;

  const PasswordRecoveryLoading(this.operation);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordRecoveryLoading &&
          runtimeType == other.runtimeType &&
          operation == other.operation;

  @override
  int get hashCode => operation.hashCode;
}

class PasswordRecoverySuccess extends PasswordRecoveryState {
  final PasswordRecoveryOperation operation;

  const PasswordRecoverySuccess(this.operation);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordRecoverySuccess &&
          runtimeType == other.runtimeType &&
          operation == other.operation;

  @override
  int get hashCode => operation.hashCode;
}

class PasswordRecoveryError extends PasswordRecoveryState {
  final PasswordRecoveryOperation operation;
  final PasswordRecoveryFailureReason reason;

  const PasswordRecoveryError(this.operation, this.reason);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordRecoveryError &&
          runtimeType == other.runtimeType &&
          operation == other.operation &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(operation, reason);
}
