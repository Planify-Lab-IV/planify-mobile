import '../../features/balances/domain/balance_direction.dart';
import '../../features/balances/domain/event_balance_line.dart';
import '../../features/balances/domain/person_balance_detail.dart';
import '../../features/balances/domain/person_balance_status.dart';
import '../../features/debts/domain/debt_settlement.dart';
import '../../features/debts/domain/debt_status.dart';
import '../../features/debts/domain/event_debt.dart';
import '../../features/debts/domain/event_debts.dart';

// Shared only by fake repositories. Identity links are explicit, never names.
class FakeSettlementStore {
  final Map<String, EventDebts> events = {};
  final Map<String, PersonBalanceDetail> people = {};
  final Map<String, ({String personKey, BalanceDirection direction})>
  relations = {};
  final Map<String, String> eventNames = {};

  void seedPerson(PersonBalanceDetail detail) {
    if (people.containsKey(detail.personKey)) return;
    people[detail.personKey] = detail;
    for (var index = 0; index < detail.breakdown.length; index++) {
      final line = detail.breakdown[index];
      eventNames[line.eventId] = line.eventName;
      final id = 'balance-${detail.personKey}-$index';
      final owes = line.direction == BalanceDirection.iOwe;
      final debt = EventDebt(
        id: id,
        eventId: line.eventId,
        debtorParticipantId: owes
            ? 'fake-viewer-${line.eventId}'
            : detail.personKey,
        debtorName: owes ? 'Lucía' : detail.displayName,
        creditorParticipantId: owes
            ? detail.personKey
            : 'fake-viewer-${line.eventId}',
        creditorName: owes ? detail.displayName : 'Lucía',
        amountCents: line.amountCents,
        status: detail.status.isSettled
            ? DebtStatus.settled
            : DebtStatus.pending,
      );
      final previous = events[line.eventId]?.debts ?? const <EventDebt>[];
      final debts = List<EventDebt>.unmodifiable([...previous, debt]);
      events[line.eventId] = EventDebts(
        debts: debts,
        allSettled: debts.every((d) => d.status.isSettled),
      );
      relations[id] = (personKey: detail.personKey, direction: line.direction);
    }
  }

  void settleDebt(String eventId, String debtId) {
    final event = events[eventId];
    if (event == null || !event.debts.any((debt) => debt.id == debtId)) {
      throw const DebtNotFoundException();
    }
    if (event.debts.firstWhere((debt) => debt.id == debtId).status.isSettled) {
      throw const DebtAlreadySettledException();
    }
    final debts = [
      for (final debt in event.debts)
        if (debt.id == debtId)
          debt.copyWith(status: DebtStatus.settled, settledAt: DateTime.now())
        else
          debt,
    ];
    events[eventId] = EventDebts(
      debts: List.unmodifiable(debts),
      allSettled: debts.isNotEmpty && debts.every((d) => d.status.isSettled),
    );
  }

  void settleWithPerson(String personKey) {
    if (!people.containsKey(personKey)) throw const DebtNotFoundException();
    final pending = [
      for (final event in events.values)
        for (final debt in event.debts)
          if (debt.status.isPending &&
              relations[debt.id]?.personKey == personKey)
            debt,
    ];
    if (pending.isEmpty) throw const DebtAlreadySettledException();
    for (final debt in pending) {
      settleDebt(debt.eventId, debt.id);
    }
  }

  PersonBalanceDetail detail(String personKey) {
    final original = people[personKey];
    if (original == null) throw const DebtNotFoundException();
    final amounts = <String, int>{};
    for (final event in events.values) {
      for (final debt in event.debts) {
        final relation = relations[debt.id];
        if (debt.status.isSettled || relation?.personKey != personKey) continue;
        final signed = relation!.direction == BalanceDirection.iOwe
            ? -debt.amountCents
            : debt.amountCents;
        amounts.update(
          debt.eventId,
          (value) => value + signed,
          ifAbsent: () => signed,
        );
      }
    }
    final net = amounts.values.fold<int>(0, (sum, value) => sum + value);
    return PersonBalanceDetail(
      personKey: personKey,
      displayName: original.displayName,
      status: net == 0
          ? PersonBalanceStatus.settled
          : net < 0
          ? PersonBalanceStatus.pay
          : PersonBalanceStatus.pending,
      netCents: net.abs(),
      breakdown: [
        for (final entry in amounts.entries)
          if (entry.value != 0)
            EventBalanceLine(
              eventId: entry.key,
              eventName: eventNames[entry.key] ?? entry.key,
              amountCents: entry.value.abs(),
              direction: entry.value < 0
                  ? BalanceDirection.iOwe
                  : BalanceDirection.owedToMe,
            ),
      ],
    );
  }
}
