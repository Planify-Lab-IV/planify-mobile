import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fake_balances_repository.dart';
import '../../domain/balances_repository.dart';
import 'balances_notifier.dart';
import 'balances_state.dart';
import 'person_balance_detail_notifier.dart';
import 'person_balance_detail_state.dart';

final balancesRepositoryProvider = Provider<BalancesRepository>((ref) {
  return FakeBalancesRepository();
});

final balancesNotifierProvider =
    StateNotifierProvider.autoDispose<BalancesNotifier, BalancesState>((ref) {
      return BalancesNotifier(
        repository: ref.watch(balancesRepositoryProvider),
      );
    });

final personBalanceDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<
      PersonBalanceDetailNotifier,
      PersonBalanceDetailState,
      String
    >((ref, personKey) {
      return PersonBalanceDetailNotifier(
        repository: ref.watch(balancesRepositoryProvider),
        personKey: personKey,
      );
    });
