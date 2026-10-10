import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/balances/data/fake_balances_repository.dart';
import 'package:planify/features/balances/domain/balance_summary.dart';
import 'package:planify/features/balances/domain/balance_direction.dart';
import 'package:planify/features/balances/domain/event_balance_line.dart';
import 'package:planify/features/balances/domain/person_balance.dart';
import 'package:planify/features/balances/domain/person_balance_detail.dart';
import 'package:planify/features/balances/domain/person_balance_status.dart';

void main() {
  group('FakeBalancesRepository', () {
    test('expone un detalle compensado por persona', () async {
      final repository = FakeBalancesRepository(delay: Duration.zero);

      final detail = await repository.getPersonDetail('user:ana');

      expect(detail.personKey, 'user:ana');
      expect(detail.netCents, -24300);
      expect(detail.breakdown, hasLength(2));
      expect(
        detail.breakdown.map((line) => line.direction),
        containsAll(<BalanceDirection>[
          BalanceDirection.iOwe,
          BalanceDirection.owedToMe,
        ]),
      );
    });

    test('permite inyectar detalles por persona', () async {
      final expected = PersonBalanceDetail(
        personKey: 'participant:marcos',
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
      final repository = FakeBalancesRepository(
        delay: Duration.zero,
        initialPersonDetails: {'participant:marcos': expected},
      );

      expect(await repository.getPersonDetail('participant:marcos'), expected);
    });

    test('no expone un desglose mutable', () async {
      final repository = FakeBalancesRepository(delay: Duration.zero);

      final detail = await repository.getPersonDetail('user:ana');

      expect(
        () => detail.breakdown.add(detail.breakdown.first),
        throwsUnsupportedError,
      );
    });

    test('falla al pedir un detalle inexistente', () {
      final repository = FakeBalancesRepository(delay: Duration.zero);

      expect(repository.getPersonDetail('missing'), throwsException);
    });

    test('expone un escenario con los tres estados de saldo', () async {
      final repository = FakeBalancesRepository(delay: Duration.zero);

      final summary = await repository.getSummary();
      final people = await repository.listPeople();

      expect(
        summary,
        const BalanceSummary(owedToMeCents: 82500, iOweCents: 24300),
      );
      expect(
        people.map((person) => person.status),
        containsAll(PersonBalanceStatus.values),
      );
      expect(
        people
            .where((person) => person.status == PersonBalanceStatus.pending)
            .fold(0, (sum, person) => sum + person.netCents.abs()),
        summary.owedToMeCents,
      );
      expect(
        people
            .where((person) => person.status == PersonBalanceStatus.pay)
            .fold(0, (sum, person) => sum + person.netCents.abs()),
        summary.iOweCents,
      );
    });

    test('permite inyectar un escenario vacío para la futura UI', () async {
      final repository = FakeBalancesRepository(
        delay: Duration.zero,
        initialSummary: const BalanceSummary(owedToMeCents: 0, iOweCents: 0),
        initialPeople: const [],
      );

      expect(
        await repository.getSummary(),
        const BalanceSummary(owedToMeCents: 0, iOweCents: 0),
      );
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
      expect(repository.getPersonDetail('user:ana'), throwsException);
    });
  });
}
