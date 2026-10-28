import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_exceptions.dart';
import '../../domain/auth_repository.dart';
import 'password_recovery_state.dart';

class PasswordRecoveryNotifier extends StateNotifier<PasswordRecoveryState> {
  final AuthRepository _repository;

  PasswordRecoveryNotifier(this._repository)
    : super(const PasswordRecoveryIdle());

  Future<void> requestPasswordReset({required String email}) async {
    const operation = PasswordRecoveryOperation.request;
    state = const PasswordRecoveryLoading(operation);

    try {
      await _repository.requestPasswordReset(email: email);
      state = const PasswordRecoverySuccess(operation);
    } on NetworkAuthException {
      state = const PasswordRecoveryError(
        operation,
        PasswordRecoveryFailureReason.networkError,
      );
    } on UnknownAuthException {
      state = const PasswordRecoveryError(
        operation,
        PasswordRecoveryFailureReason.unknown,
      );
    } catch (_) {
      state = const PasswordRecoveryError(
        operation,
        PasswordRecoveryFailureReason.unknown,
      );
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    const operation = PasswordRecoveryOperation.reset;
    state = const PasswordRecoveryLoading(operation);

    try {
      await _repository.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      state = const PasswordRecoverySuccess(operation);
    } on InvalidResetCodeException {
      state = const PasswordRecoveryError(
        operation,
        PasswordRecoveryFailureReason.invalidResetCode,
      );
    } on InvalidResetDataException {
      state = const PasswordRecoveryError(
        operation,
        PasswordRecoveryFailureReason.invalidResetData,
      );
    } on NetworkAuthException {
      state = const PasswordRecoveryError(
        operation,
        PasswordRecoveryFailureReason.networkError,
      );
    } on UnknownAuthException {
      state = const PasswordRecoveryError(
        operation,
        PasswordRecoveryFailureReason.unknown,
      );
    } catch (_) {
      state = const PasswordRecoveryError(
        operation,
        PasswordRecoveryFailureReason.unknown,
      );
    }
  }
}
