import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/balances/data/fake_balances_repository.dart';
import 'package:planify/features/balances/domain/balance_direction.dart';
import 'package:planify/features/balances/domain/balance_summary.dart';
import 'package:planify/features/balances/domain/balances_repository.dart';
import 'package:planify/features/balances/domain/event_balance_line.dart';
import 'package:planify/features/balances/domain/person_balance.dart';
import 'package:planify/features/balances/domain/person_balance_detail.dart';
import 'package:planify/features/balances/domain/person_balance_status.dart';
import 'package:planify/features/balances/presentation/controllers/person_balance_detail_notifier.dart';
import 'package:planify/features/balances/presentation/controllers/person_balance_detail_state.dart';

void main() {
  group('PersonBalanceDetailNotifier', () {
    test('carga el detalle de la persona al crearse', () async {
      final notifier = PersonBalanceDetailNotifier(
        repository: FakeBalancesRepository(delay: Duration.zero),
        personKey: 'user:ana',
      );

      expect(notifier.state.isLoading, isTrue);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.loadStatus, PersonBalanceDetailLoadStatus.success);
      expect(notifier.state.detail?.personKey, 'user:ana');
      expect(notifier.state.detail?.breakdown, hasLength(2));
      notifier.dispose();
    });

    test('expone error cuando el repositorio falla', () async {
      final notifier = PersonBalanceDetailNotifier(
        repository: FakeBalancesRepository(
          delay: Duration.zero,
          shouldThrowError: true,
        ),
        personKey: 'user:ana',
      );

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.loadStatus, PersonBalanceDetailLoadStatus.error);
      expect(notifier.state.detail, isNull);
      notifier.dispose();
    });

    test('reload vuelve a consultar el detalle de la misma persona', () async {
      final repository = _CountingPersonDetailRepository();
      final notifier = PersonBalanceDetailNotifier(
        repository: repository,
        personKey: 'participant:marcos',
      );

      await Future<void>.delayed(Duration.zero);
      await notifier.reload();

      expect(repository.detailCalls, 2);
      expect(repository.requestedPersonKeys, [
        'participant:marcos',
        'participant:marcos',
      ]);
      expect(notifier.state.isSuccess, isTrue);
      notifier.dispose();
    });
  });
}

class _CountingPersonDetailRepository implements BalancesRepository {
  int detailCalls = 0;
  final List<String> requestedPersonKeys = [];

  @override
  Future<PersonBalanceDetail> getPersonDetail(String personKey) async {
    detailCalls++;
    requestedPersonKeys.add(personKey);
    return PersonBalanceDetail(
      personKey: personKey,
      displayName: 'Marcos',
      status: PersonBalanceStatus.pending,
      netCents: 20000,
      breakdown: const [
        EventBalanceLine(
          eventId: 'event:asado',
          eventName: 'Asado',
          amountCents: 20000,
          direction: BalanceDirection.owedToMe,
        ),
      ],
    );
  }

  @override
  Future<BalanceSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<List<PersonBalance>> listPeople() {
    throw UnimplementedError();
  }
}
