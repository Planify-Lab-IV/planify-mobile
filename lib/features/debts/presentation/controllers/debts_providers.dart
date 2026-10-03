import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fake_debts_repository.dart';
import '../../domain/debts_repository.dart';
import 'event_debts_notifier.dart';
import 'event_debts_state.dart';
import '../../../../core/providers/fake_settlement_provider.dart';

final debtsRepositoryProvider = Provider<DebtsRepository>((ref) {
  return FakeDebtsRepository(store: ref.watch(fakeSettlementStoreProvider));
});

// Existing subscribed views refresh after any settlement, without recreating
// autoDispose notifiers or starting requests for screens that are not open.
final settlementRevisionProvider = StateProvider<int>((ref) => 0);

final eventDebtsNotifierProvider = StateNotifierProvider.autoDispose
    .family<EventDebtsNotifier, EventDebtsState, String>((ref, eventId) {
      final notifier = EventDebtsNotifier(
        repository: ref.watch(debtsRepositoryProvider),
        eventId: eventId,
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
