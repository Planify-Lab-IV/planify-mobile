import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/balance_summary.dart';
import '../../domain/balances_repository.dart';
import '../../domain/person_balance.dart';
import 'balances_state.dart';

class BalancesNotifier extends StateNotifier<BalancesState> {
  final BalancesRepository repository;

  BalancesNotifier({required this.repository}) : super(const BalancesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loadStatus: BalancesLoadStatus.loading);

    try {
      final results = await Future.wait<Object>([
        repository.getSummary(),
        repository.listPeople(),
      ]);
      if (!mounted) return;

      state = state.copyWith(
        summary: results[0] as BalanceSummary,
        people: results[1] as List<PersonBalance>,
        loadStatus: BalancesLoadStatus.success,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loadStatus: BalancesLoadStatus.error);
    }
  }

  Future<void> reload() => load();
}
