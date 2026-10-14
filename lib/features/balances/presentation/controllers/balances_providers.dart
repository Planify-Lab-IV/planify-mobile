import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/http_balances_repository.dart';
import '../../domain/balances_repository.dart';
import 'balances_notifier.dart';
import 'balances_state.dart';
import 'person_balance_detail_notifier.dart';
import 'person_balance_detail_state.dart';
import '../../../debts/presentation/controllers/debts_providers.dart';

final balancesRepositoryProvider = Provider<BalancesRepository>((ref) {
  return HttpBalancesRepository(dio: ref.watch(dioClientProvider));
});

final balancesNotifierProvider =
    StateNotifierProvider.autoDispose<BalancesNotifier, BalancesState>((ref) {
      final notifier = BalancesNotifier(
        repository: ref.watch(balancesRepositoryProvider),
      );
      ref.listen(
        settlementRevisionProvider,
        (_, _) => notifier.reload(silent: true),
      );
      return notifier;
    });

final personBalanceDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<PersonBalanceDetailNotifier, PersonBalanceDetailState, String>((
      ref,
      personKey,
    ) {
      final notifier = PersonBalanceDetailNotifier(
        repository: ref.watch(balancesRepositoryProvider),
        personKey: personKey,
        debtsRepository: ref.watch(debtsRepositoryProvider),
        onSettled: () => ref.read(settlementRevisionProvider.notifier).state++,
      );
      void Function()? releaseOperation;
      ref.onDispose(
        notifier.addListener((state) {
          if (state.isSettling) {
            releaseOperation ??= ref.keepAlive().close;
          } else {
            releaseOperation?.call();
            releaseOperation = null;
          }
        }, fireImmediately: false),
      );
      ref.listen(
        settlementRevisionProvider,
        (_, _) => notifier.reload(silent: true),
      );
      return notifier;
    });
