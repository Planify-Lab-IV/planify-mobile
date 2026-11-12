import 'package:flutter_test/flutter_test.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/auth_exceptions.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/password_recovery_notifier.dart';
import 'package:planify/features/auth/presentation/controllers/password_recovery_state.dart';

void main() {
  group('PasswordRecoveryNotifier', () {
    late FakeSecureStorage storage;
    late PasswordRecoveryNotifier notifier;

    setUp(() {
      storage = FakeSecureStorage();
      notifier = PasswordRecoveryNotifier(
        FakeAuthRepository(storage: storage, delay: Duration.zero),
      );
    });

    test('solicita un código con la transición de estado esperada', () async {
      final states = <PasswordRecoveryState>[];
      notifier.addListener(states.add);

      await notifier.requestPasswordReset(email: 'lucas@planify.com');

      expect(states, [
        const PasswordRecoveryIdle(),
        const PasswordRecoveryLoading(PasswordRecoveryOperation.request),
        const PasswordRecoverySuccess(PasswordRecoveryOperation.request),
      ]);
    });

    test('informa un error de red al solicitar el código', () async {
      await notifier.requestPasswordReset(email: 'network.error@planify.com');

      expect(
        notifier.state,
        const PasswordRecoveryError(
          PasswordRecoveryOperation.request,
          PasswordRecoveryFailureReason.networkError,
        ),
      );
    });

    test('confirma un reset exitoso sin cambiar el estado de sesión', () async {
      await notifier.resetPassword(
        email: 'lucas@planify.com',
        code: '123456',
        newPassword: 'password123',
      );

      expect(
        notifier.state,
        const PasswordRecoverySuccess(PasswordRecoveryOperation.reset),
      );
      expect(await storage.getToken(), isNull);
    });

    test('mapea un código inválido al motivo específico', () async {
      await notifier.resetPassword(
        email: 'lucas@planify.com',
        code: '000000',
        newPassword: 'password123',
      );

      expect(
        notifier.state,
        const PasswordRecoveryError(
          PasswordRecoveryOperation.reset,
          PasswordRecoveryFailureReason.invalidResetCode,
        ),
      );
    });

    test('mapea datos inválidos al motivo específico', () async {
      await notifier.resetPassword(
        email: 'lucas@planify.com',
        code: '123456',
        newPassword: 'short',
      );

      expect(
        notifier.state,
        const PasswordRecoveryError(
          PasswordRecoveryOperation.reset,
          PasswordRecoveryFailureReason.invalidResetData,
        ),
      );
    });

    test('mapea errores de red al restablecer', () async {
      await notifier.resetPassword(
        email: 'network.error@planify.com',
        code: '123456',
        newPassword: 'password123',
      );

      expect(
        notifier.state,
        const PasswordRecoveryError(
          PasswordRecoveryOperation.reset,
          PasswordRecoveryFailureReason.networkError,
        ),
      );
    });

    test('mapea fallos inesperados al motivo unknown', () async {
      notifier = PasswordRecoveryNotifier(
        _UnknownPasswordRecoveryRepository(storage: storage),
      );

      await notifier.resetPassword(
        email: 'lucas@planify.com',
        code: '123456',
        newPassword: 'password123',
      );

      expect(
        notifier.state,
        const PasswordRecoveryError(
          PasswordRecoveryOperation.reset,
          PasswordRecoveryFailureReason.unknown,
        ),
      );
    });
  });
}

class _UnknownPasswordRecoveryRepository extends FakeAuthRepository {
  _UnknownPasswordRecoveryRepository({required SecureStorage storage})
    : super(storage: storage, delay: Duration.zero);

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    throw const UnknownAuthException();
  }
}
