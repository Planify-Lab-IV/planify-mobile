import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/balances/data/fake_balances_repository.dart';
import 'package:planify/features/balances/domain/balance_summary.dart';
import 'package:planify/features/balances/domain/person_balance.dart';
import 'package:planify/features/balances/domain/person_balance_status.dart';

void main() {
  group('FakeBalancesRepository', () {
    test('expone un escenario con los tres estados de saldo', () async {
      final repository = FakeBalancesRepository(delay: Duration.zero);

      final summary = await repository.getSummary();
      final people = await repository.listPeople();

      expect(summary, const BalanceSummary(owedToMeCents: 82500, iOweCents: 24300));
      expect(people.map((person) => person.status), containsAll(PersonBalanceStatus.values));
    });

    test('permite inyectar un escenario vacío para la futura UI', () async {
      final repository = FakeBalancesRepository(
        delay: Duration.zero,
        initialSummary: const BalanceSummary(owedToMeCents: 0, iOweCents: 0),
        initialPeople: const [],
      );

      expect(await repository.getSummary(), const BalanceSummary(owedToMeCents: 0, iOweCents: 0));
      expect(await repository.listPeople(), isEmpty);
    });

    test('no expone una lista mutable de su estado interno', () async {
      final repository = FakeBalancesRepository(
        delay: Duration.zero,
        initialPeople: const [
          PersonBalance(
            personKey: 'participant:marcos',
            displayName: 'Marcos',
            status: PersonBalanceStatus.pending,
            netCents: 1000,
          ),
        ],
      );

      final people = await repository.listPeople();

      expect(() => people.add(people.single), throwsUnsupportedError);
    });

    test('simula un error cuando se configura shouldThrowError', () async {
      final repository = FakeBalancesRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      );

      expect(repository.getSummary(), throwsException);
      expect(repository.listPeople(), throwsException);
    });
  });
}
