import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/balance_summary.dart';
import '../../domain/balances_repository.dart';
import '../../domain/person_balance.dart';
import 'balances_state.dart';

class BalancesNotifier extends StateNotifier<BalancesState> {
  final BalancesRepository repository;
  int _loadVersion = 0;

  BalancesNotifier({required this.repository}) : super(const BalancesState()) {
    load();
  }

  Future<void> load({bool silent = false}) async {
    final version = ++_loadVersion;
    final preserve = silent && state.isSuccess;
    if (!preserve) {
      state = state.copyWith(loadStatus: BalancesLoadStatus.loading);
    }

    try {
      final results = await Future.wait<Object>([
        repository.getSummary(),
        repository.listPeople(),
      ]);
      if (!mounted || version != _loadVersion) return;

      state = state.copyWith(
        summary: results[0] as BalanceSummary,
        people: results[1] as List<PersonBalance>,
        loadStatus: BalancesLoadStatus.success,
      );
    } catch (_) {
      if (!mounted || version != _loadVersion) return;
      if (!preserve) {
        state = state.copyWith(loadStatus: BalancesLoadStatus.error);
      }
    }
  }

  Future<void> reload({bool silent = false}) => load(silent: silent);
}
