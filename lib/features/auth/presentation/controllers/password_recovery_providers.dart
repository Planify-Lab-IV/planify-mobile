import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';
import 'password_recovery_notifier.dart';
import 'password_recovery_state.dart';

final passwordRecoveryNotifierProvider =
    StateNotifierProvider.autoDispose<
      PasswordRecoveryNotifier,
      PasswordRecoveryState
    >((ref) {
      return PasswordRecoveryNotifier(ref.watch(authRepositoryProvider));
    });
