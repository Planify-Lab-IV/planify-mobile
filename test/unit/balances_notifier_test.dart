import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/balances/data/fake_balances_repository.dart';
import 'package:planify/features/balances/domain/balance_summary.dart';
import 'package:planify/features/balances/domain/balances_repository.dart';
import 'package:planify/features/balances/domain/person_balance.dart';
import 'package:planify/features/balances/domain/person_balance_status.dart';
import 'package:planify/features/balances/presentation/controllers/balances_notifier.dart';
import 'package:planify/features/balances/presentation/controllers/balances_state.dart';

void main() {
  group('BalancesNotifier', () {
    test('carga resumen y personas juntos al crearse', () async {
      final notifier = BalancesNotifier(
        repository: FakeBalancesRepository(delay: Duration.zero),
      );

      expect(notifier.state.isLoading, isTrue);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.loadStatus, BalancesLoadStatus.success);
      expect(notifier.state.summary.owedToMeCents, 82500);
      expect(notifier.state.summary.iOweCents, 24300);
      expect(notifier.state.people, hasLength(3));
      notifier.dispose();
    });

    test('expone error si falla cualquiera de las dos consultas', () async {
      final notifier = BalancesNotifier(
        repository: FakeBalancesRepository(
          delay: Duration.zero,
          shouldThrowError: true,
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.loadStatus, BalancesLoadStatus.error);
      expect(notifier.state.people, isEmpty);
      notifier.dispose();
    });

    test('reload vuelve a consultar resumen y personas', () async {
      final repository = _CountingBalancesRepository();
      final notifier = BalancesNotifier(repository: repository);

      await Future<void>.delayed(Duration.zero);
      await notifier.reload();

      expect(repository.summaryCalls, 2);
      expect(repository.peopleCalls, 2);
      expect(notifier.state.loadStatus, BalancesLoadStatus.success);
      notifier.dispose();
    });
  });
}

class _CountingBalancesRepository implements BalancesRepository {
  int summaryCalls = 0;
  int peopleCalls = 0;

  @override
  Future<BalanceSummary> getSummary() async {
    summaryCalls++;
    return const BalanceSummary(owedToMeCents: 1000, iOweCents: 0);
  }

  @override
  Future<List<PersonBalance>> listPeople() async {
    peopleCalls++;
    return const [
      PersonBalance(
        personKey: 'user:ana',
        displayName: 'Ana',
        status: PersonBalanceStatus.pay,
        netCents: 1000,
      ),
    ];
  }
}
