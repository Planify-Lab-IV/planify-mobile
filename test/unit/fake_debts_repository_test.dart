import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/debts/data/fake_debts_repository.dart';
import 'package:planify/features/debts/domain/debt_status.dart';

void main() {
  group('FakeDebtsRepository', () {
    test('devuelve dos deudas pendientes y una saldada para evt-123', () async {
      final repository = FakeDebtsRepository(delay: Duration.zero);

      final eventDebts = await repository.listEventDebts('evt-123');

      expect(eventDebts.debts, hasLength(3));
      expect(eventDebts.allSettled, isFalse);
      expect(
        eventDebts.debts.where((debt) => debt.status == DebtStatus.pending),
        hasLength(2),
      );
      expect(
        eventDebts.debts.where((debt) => debt.status == DebtStatus.settled),
        hasLength(1),
      );
    });

    test('devuelve una lista vacía para un evento sin deudas', () async {
      final repository = FakeDebtsRepository(delay: Duration.zero);

      final eventDebts = await repository.listEventDebts('evt-fake-demo');

      expect(eventDebts.debts, isEmpty);
      expect(eventDebts.allSettled, isFalse);
    });

    test('simula un error cuando se configura shouldThrowError', () async {
      final repository = FakeDebtsRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      );

      expect(repository.listEventDebts('evt-123'), throwsException);
    });
  });
}
