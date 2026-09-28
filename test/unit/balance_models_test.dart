import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/balances/domain/balance_summary.dart';
import 'package:planify/features/balances/domain/person_balance.dart';
import 'package:planify/features/balances/domain/person_balance_status.dart';

void main() {
  group('BalanceSummary', () {
    const summary = BalanceSummary(owedToMeCents: 12500, iOweCents: 7300);

    test('copyWith conserva los valores que no se reemplazan', () {
      final updated = summary.copyWith(iOweCents: 8100);

      expect(updated.owedToMeCents, 12500);
      expect(updated.iOweCents, 8100);
    });

    test('compara sus instancias por valor', () {
      expect(
        summary,
        const BalanceSummary(owedToMeCents: 12500, iOweCents: 7300),
      );
      expect(
        summary,
        isNot(const BalanceSummary(owedToMeCents: 0, iOweCents: 7300)),
      );
    });
  });

  group('PersonBalance', () {
    const balance = PersonBalance(
      personKey: 'user:ana',
      displayName: 'Ana',
      status: PersonBalanceStatus.pay,
      netCents: 12500,
    );

    test('copyWith permite actualizar un saldo sin perder su clave opaca', () {
      final updated = balance.copyWith(
        status: PersonBalanceStatus.settled,
        netCents: 0,
      );

      expect(updated.personKey, 'user:ana');
      expect(updated.displayName, 'Ana');
      expect(updated.status, PersonBalanceStatus.settled);
      expect(updated.netCents, 0);
    });

    test('compara sus instancias por valor', () {
      expect(
        balance,
        const PersonBalance(
          personKey: 'user:ana',
          displayName: 'Ana',
          status: PersonBalanceStatus.pay,
          netCents: 12500,
        ),
      );
    });
  });

  test('PersonBalanceStatus expone sus estados semánticos', () {
    expect(PersonBalanceStatus.pay.isPay, isTrue);
    expect(PersonBalanceStatus.pending.isPending, isTrue);
    expect(PersonBalanceStatus.settled.isSettled, isTrue);
  });
}
