import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fake_balances_repository.dart';
import '../../domain/balances_repository.dart';
import 'balances_notifier.dart';
import 'balances_state.dart';

final balancesRepositoryProvider = Provider<BalancesRepository>((ref) {
  return FakeBalancesRepository();
});

final balancesNotifierProvider =
    StateNotifierProvider.autoDispose<BalancesNotifier, BalancesState>((ref) {
      return BalancesNotifier(
        repository: ref.watch(balancesRepositoryProvider),
      );
    });
