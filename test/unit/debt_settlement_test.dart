import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planify/core/data/fake_settlement_store.dart';
import 'package:planify/features/debts/data/fake_debts_repository.dart';
import 'package:planify/features/debts/domain/debt_settlement.dart';
import 'package:planify/features/debts/domain/debt_status.dart';
import 'package:planify/features/debts/domain/event_debt.dart';
import 'package:planify/features/debts/domain/event_debts.dart';
import 'package:planify/features/debts/presentation/controllers/event_debts_notifier.dart';
import 'package:planify/features/debts/presentation/controllers/debts_providers.dart';
import 'package:planify/features/balances/data/fake_balances_repository.dart';
import 'package:planify/features/balances/presentation/controllers/balances_notifier.dart';
import 'package:planify/features/balances/presentation/controllers/balances_providers.dart';
import 'package:planify/features/balances/presentation/controllers/person_balance_detail_notifier.dart';

const debt = EventDebt(
  id: 'd',
  eventId: 'e',
  debtorParticipantId: 'debtor',
  debtorName: 'Ana',
  creditorParticipantId: 'creditor',
  creditorName: 'Lucía',
  amountCents: 10000,
  status: DebtStatus.pending,
);

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'closing sheet during mutation still refreshes subscribed balances',
    () async {
      final store = FakeSettlementStore();
      final balances = FakeBalancesRepository(
        delay: Duration.zero,
        store: store,
      );
      final debts = _HeldCascadeRepository(store);
      final container = ProviderContainer(
        overrides: [
          balancesRepositoryProvider.overrideWithValue(balances),
          debtsRepositoryProvider.overrideWithValue(debts),
        ],
      );
      addTearDown(container.dispose);
      container.listen(balancesNotifierProvider, (_, _) {});
      final sheet = container.listen(
        personBalanceDetailNotifierProvider('user:ana'),
        (_, _) {},
      );
      await flush();
      final n = container.read(
        personBalanceDetailNotifierProvider('user:ana').notifier,
      );
      final operation = n.settleWithPerson();
      sheet.close();
      await container.pump();
      expect(n.mounted, isTrue);
      debts.gate.complete();
      expect(await operation, DebtSettlementResult.success);
      await flush();
      expect(
        container.read(balancesNotifierProvider).people.first.status.isSettled,
        isTrue,
      );
    },
  );
  group('settlement permissions', () {
    for (final actor in ['debtor', 'creditor']) {
      test('allows $actor', () => expect(canSettleDebt(debt, actor), isTrue));
    }
    for (final actor in <String?>[null, '', ' ', 'other']) {
      test('rejects $actor', () => expect(canSettleDebt(debt, actor), isFalse));
    }
    test(
      'settled debt has no action',
      () => expect(
        canSettleDebt(debt.copyWith(status: DebtStatus.settled), 'debtor'),
        isFalse,
      ),
    );
  });

  group('fake mutations', () {
    test(
      'seeds one navigable event debt and exposes its person in balances',
      () async {
        final store = FakeSettlementStore();
        final balances = FakeBalancesRepository(
          delay: Duration.zero,
          store: store,
        );
        final debts = FakeDebtsRepository(
          delay: Duration.zero,
          store: store,
          initialEventDebts: const {},
        );

        final created = debts.ensureEventFixture(
          eventId: 'created-event',
          eventName: 'Evento creado',
          currentParticipantId: 'participant-me',
          counterpartyParticipantId: 'participant-ana',
          counterpartyPersonKey: 'user:ana-created',
          counterpartyName: 'Ana',
        );
        final duplicate = debts.ensureEventFixture(
          eventId: 'created-event',
          eventName: 'Evento creado',
          currentParticipantId: 'participant-me',
          counterpartyParticipantId: 'participant-ana',
          counterpartyPersonKey: 'user:ana-created',
          counterpartyName: 'Ana',
        );

        expect(created, isTrue);
        expect(duplicate, isFalse);
        final eventDebts = await debts.listEventDebts('created-event');
        expect(eventDebts.debts, hasLength(1));
        expect(eventDebts.debts.single.creditorParticipantId, 'participant-me');
        expect(eventDebts.debts.single.debtorParticipantId, 'participant-ana');
        expect(
          (await balances.listPeople()).any(
            (person) =>
                person.personKey == 'user:ana-created' &&
                person.netCents == 50000,
          ),
          isTrue,
        );

        await debts.settleDebt('created-event', eventDebts.debts.single.id);
        expect(
          (await balances.getPersonDetail('user:ana-created')).status.isSettled,
          isTrue,
        );
      },
    );

    test('marks only the selected debt and computes allSettled', () async {
      final repo = FakeDebtsRepository(
        delay: Duration.zero,
        initialEventDebts: {
          'e': EventDebts(
            debts: [
              debt,
              debt.copyWith(id: 'other'),
            ],
            allSettled: false,
          ),
        },
      );
      await repo.settleDebt('e', 'd');
      var result = await repo.listEventDebts('e');
      expect(result.debts.first.status, DebtStatus.settled);
      expect(result.debts.first.settledAt, isNotNull);
      expect(result.debts.last.status, DebtStatus.pending);
      expect(result.allSettled, isFalse);
      await repo.settleDebt('e', 'other');
      result = await repo.listEventDebts('e');
      expect(result.allSettled, isTrue);
      await expectLater(
        repo.settleDebt('e', 'd'),
        throwsA(isA<DebtAlreadySettledException>()),
      );
      await expectLater(
        repo.settleDebt('missing', 'd'),
        throwsA(isA<DebtNotFoundException>()),
      );
      await expectLater(
        repo.settleDebt('e', 'missing'),
        throwsA(isA<DebtNotFoundException>()),
      );
    });

    test(
      'cascade clears common events, preserving other people and summary',
      () async {
        final store = FakeSettlementStore();
        final balances = FakeBalancesRepository(
          delay: Duration.zero,
          store: store,
        );
        final debts = FakeDebtsRepository(delay: Duration.zero, store: store);
        await debts.settleWithPerson('user:ana');
        final detail = await balances.getPersonDetail('user:ana');
        expect(detail.status.isSettled, isTrue);
        expect(detail.netCents, 0);
        expect(detail.breakdown, isEmpty);
        expect((await balances.getSummary()).iOweCents, 0);
        expect((await balances.getSummary()).owedToMeCents, 82500);
        expect((await debts.listEventDebts('event:asado')).allSettled, isTrue);
        expect((await debts.listEventDebts('event:cine')).allSettled, isTrue);
        expect(
          (await balances.getPersonDetail('participant:martin')).netCents,
          82500,
        );
        await expectLater(
          debts.settleWithPerson('user:ana'),
          throwsA(isA<DebtAlreadySettledException>()),
        );
        await expectLater(
          debts.settleWithPerson('unknown'),
          throwsA(isA<DebtNotFoundException>()),
        );
      },
    );

    test('punctual settlement updates global net in both directions', () async {
      final store = FakeSettlementStore();
      final balances = FakeBalancesRepository(
        delay: Duration.zero,
        store: store,
      );
      final debts = FakeDebtsRepository(delay: Duration.zero, store: store);
      await debts.settleDebt('event:asado', 'balance-user:ana-0');
      expect((await balances.getPersonDetail('user:ana')).netCents, 25700);
      expect(
        (await balances.getPersonDetail('user:ana')).status.name,
        'pending',
      );
      await debts.settleDebt('event:cine', 'balance-user:ana-1');
      expect(
        (await balances.getPersonDetail('user:ana')).status.isSettled,
        isTrue,
      );
    });
  });

  group('event notifier', () {
    Future<EventDebtsNotifier> notifier(FakeDebtsRepository repo) async {
      final result = EventDebtsNotifier(repository: repo, eventId: 'evt-123');
      addTearDown(result.dispose);
      await flush();
      return result;
    }

    test(
      'success preserves rows, ignores repeat and refuses outsiders',
      () async {
        final repo = FakeDebtsRepository(delay: Duration.zero);
        final n = await notifier(repo);
        expect(
          await n.settleDebt('missing', 'other'),
          DebtSettlementResult.notFound,
        );
        expect(
          await n.settleDebt('debt-evt-123-1', 'other'),
          DebtSettlementResult.forbidden,
        );
        expect(repo.settlementCalls, 0);
        expect(
          await n.settleDebt('debt-evt-123-1', 'participant-org-evt-123'),
          DebtSettlementResult.success,
        );
        expect(n.state.isSuccess, isTrue);
        expect(n.state.eventDebts.debts, hasLength(3));
        expect(n.state.eventDebts.debts.first.status.isSettled, isTrue);
        expect(
          await n.settleDebt('debt-evt-123-1', 'participant-org-evt-123'),
          DebtSettlementResult.alreadySettled,
        );
        expect(repo.settlementCalls, 1);
      },
    );

    test('409 refreshes a concurrently settled row', () async {
      final repo = FakeDebtsRepository(delay: Duration.zero);
      final n = await notifier(repo);
      await repo.settleDebt('evt-123', 'debt-evt-123-1');
      expect(
        await n.settleDebt('debt-evt-123-1', 'participant-org-evt-123'),
        DebtSettlementResult.alreadySettled,
      );
      expect(n.state.eventDebts.debts.first.status.isSettled, isTrue);
    });

    for (final error in <DebtException>[
      const DebtAuthorizationException(),
      const DebtNotFoundException(),
      const DebtNetworkException(),
      const DebtAlreadySettledException(),
    ]) {
      test('handles ${error.runtimeType}, keeping data', () async {
        final repo = FakeDebtsRepository(
          delay: Duration.zero,
          settlementError: error,
        );
        final n = await notifier(repo);
        expect(
          await n.settleDebt('debt-evt-123-1', 'participant-org-evt-123'),
          settlementError(error),
        );
        expect(n.state.isSettling, isFalse);
        expect(n.state.isSuccess, isTrue);
        expect(n.state.eventDebts.debts, hasLength(3));
      });
    }

    test('double call reaches repository only once', () async {
      final repo = _HeldRepository();
      final n = await notifier(repo);
      final first = n.settleDebt('debt-evt-123-1', 'participant-org-evt-123');
      expect(n.state.isSettling, isTrue);
      expect(
        await n.settleDebt('debt-evt-123-1', 'participant-org-evt-123'),
        DebtSettlementResult.ignored,
      );
      repo.gate.complete();
      expect(await first, DebtSettlementResult.success);
      expect(repo.settlementCalls, 1);
    });

    test('silent reload failure keeps previously visible data', () async {
      final repo = FakeDebtsRepository(delay: Duration.zero);
      final n = await notifier(repo);
      final previous = n.state.eventDebts;
      repo.shouldThrowError = true;
      await n.reload(silent: true);
      expect(n.state.eventDebts, previous);
      expect(n.state.isSuccess, isTrue);
      expect(n.state.isRefreshing, isFalse);
    });
  });

  group('person notifier', () {
    test('success reloads silently and preserves another balance', () async {
      final store = FakeSettlementStore();
      final balances = FakeBalancesRepository(
        delay: Duration.zero,
        store: store,
      );
      final debts = FakeDebtsRepository(delay: Duration.zero, store: store);
      var changes = 0;
      final n = PersonBalanceDetailNotifier(
        repository: balances,
        debtsRepository: debts,
        personKey: 'user:ana',
        onSettled: () => changes++,
      );
      addTearDown(n.dispose);
      await flush();
      expect(await n.settleWithPerson(), DebtSettlementResult.success);
      expect(n.state.detail!.status.isSettled, isTrue);
      expect(n.state.isSettling, isFalse);
      expect(changes, 1);
      expect(await n.settleWithPerson(), DebtSettlementResult.alreadySettled);
    });

    for (final error in <DebtException>[
      const DebtAuthorizationException(),
      const DebtNotFoundException(),
      const DebtNetworkException(),
      const DebtAlreadySettledException(),
    ]) {
      test(
        'maps ${error.runtimeType} without dropping the sheet data',
        () async {
          final repo = FakeBalancesRepository(delay: Duration.zero);
          final debts = FakeDebtsRepository(
            delay: Duration.zero,
            settlementError: error,
          );
          final n = PersonBalanceDetailNotifier(
            repository: repo,
            debtsRepository: debts,
            personKey: 'user:ana',
          );
          addTearDown(n.dispose);
          await flush();
          expect(await n.settleWithPerson(), settlementError(error));
          expect(n.state.detail?.displayName, 'Ana');
          expect(n.state.isSuccess, isTrue);
          expect(n.state.isSettling, isFalse);
          repo.shouldThrowError = true;
          await n.reload(silent: true);
          expect(n.state.detail?.displayName, 'Ana');
          expect(n.state.isSuccess, isTrue);
        },
      );
    }

    test(
      'double call is ignored and late completion after disposal is safe',
      () async {
        final repo = _HeldRepository();
        final n = PersonBalanceDetailNotifier(
          repository: FakeBalancesRepository(delay: Duration.zero),
          debtsRepository: repo,
          personKey: 'user:ana',
        );
        await flush();
        final first = n.settleWithPerson();
        expect(await n.settleWithPerson(), DebtSettlementResult.ignored);
        n.dispose();
        repo.gate.complete();
        expect(await first, DebtSettlementResult.ignored);
      },
    );
  });

  test('global silent refresh preserves previous success on failure', () async {
    final repo = FakeBalancesRepository(delay: Duration.zero);
    final n = BalancesNotifier(repository: repo);
    addTearDown(n.dispose);
    await flush();
    repo.shouldThrowError = true;
    await n.reload(silent: true);
    expect(n.state.isSuccess, isTrue);
    expect(n.state.people, hasLength(3));
  });

  test(
    'subscribed provider views refresh together and containers stay isolated',
    () async {
      final container = ProviderContainer();
      final other = ProviderContainer();
      addTearDown(container.dispose);
      addTearDown(other.dispose);
      container.listen(balancesNotifierProvider, (_, _) {});
      container.listen(
        personBalanceDetailNotifierProvider('user:ana'),
        (_, _) {},
      );
      container.listen(eventDebtsNotifierProvider('evt-123'), (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final result = await container
          .read(personBalanceDetailNotifierProvider('user:ana').notifier)
          .settleWithPerson();
      expect(result, DebtSettlementResult.success);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(
        container.read(balancesNotifierProvider).people.first.status.isSettled,
        isTrue,
      );
      expect(
        container
            .read(eventDebtsNotifierProvider('evt-123'))
            .eventDebts
            .debts
            .first
            .status
            .isSettled,
        isTrue,
      );
      final unaffected = await other
          .read(balancesRepositoryProvider)
          .getPersonDetail('user:ana');
      expect(unaffected.status.isSettled, isFalse);
    },
  );
}

class _HeldRepository extends FakeDebtsRepository {
  final gate = Completer<void>();
  _HeldRepository() : super(delay: Duration.zero);
  @override
  Future<void> settleDebt(String eventId, String debtId) async {
    await gate.future;
    await super.settleDebt(eventId, debtId);
  }

  @override
  Future<void> settleWithPerson(String personKey) async {
    await gate.future;
    throw const DebtNetworkException();
  }
}

class _HeldCascadeRepository extends FakeDebtsRepository {
  final gate = Completer<void>();
  _HeldCascadeRepository(FakeSettlementStore store)
    : super(store: store, delay: Duration.zero);
  @override
  Future<void> settleWithPerson(String personKey) async {
    await gate.future;
    await super.settleWithPerson(personKey);
  }
}
