import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fake_debts_repository.dart';
import '../../domain/debts_repository.dart';
import 'event_debts_notifier.dart';
import 'event_debts_state.dart';

final debtsRepositoryProvider = Provider<DebtsRepository>((ref) {
  return FakeDebtsRepository();
});

final eventDebtsNotifierProvider = StateNotifierProvider.autoDispose
    .family<EventDebtsNotifier, EventDebtsState, String>((ref, eventId) {
      return EventDebtsNotifier(
        repository: ref.watch(debtsRepositoryProvider),
        eventId: eventId,
      );
    });
