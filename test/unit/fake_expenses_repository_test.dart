import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/expenses/data/fake_expenses_repository.dart';

void main() {
  group('FakeExpensesRepository', () {
    test('registra el cierre de gastos para un evento', () async {
      final repository = FakeExpensesRepository(delay: Duration.zero);

      await repository.closeExpenses('evt-1');

      expect(repository.areExpensesClosedFor('evt-1'), isTrue);
    });

    test('no registra el cierre cuando está configurado para fallar', () async {
      final repository = FakeExpensesRepository(
        delay: Duration.zero,
        shouldFailClosingExpenses: true,
      );

      await expectLater(
        repository.closeExpenses('evt-1'),
        throwsException,
      );

      expect(repository.areExpensesClosedFor('evt-1'), isFalse);
    });
  });
}
