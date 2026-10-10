import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fake_settlement_store.dart';
import '../../features/balances/data/fake_balances_repository.dart';
import '../../features/debts/data/fake_debts_repository.dart';
import '../../features/balances/domain/balance_direction.dart';

final fakeSettlementStoreProvider = Provider<FakeSettlementStore>((ref) {
  final store = FakeSettlementStore();
  FakeBalancesRepository(store: store);
  FakeDebtsRepository(store: store);
  // Explicit link for the viewer Lucía in evt-123; unrelated debts stay untouched.
  store.eventNames['evt-123'] = 'Cumpleaños de Lucas';
  store.relations['debt-evt-123-1'] = (
    personKey: 'user:ana',
    direction: BalanceDirection.owedToMe,
  );
  return store;
});
