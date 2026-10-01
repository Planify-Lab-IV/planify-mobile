import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/balances_repository.dart';
import 'person_balance_detail_state.dart';

class PersonBalanceDetailNotifier
    extends StateNotifier<PersonBalanceDetailState> {
  final BalancesRepository _repository;
  final String _personKey;

  PersonBalanceDetailNotifier({
    required BalancesRepository repository,
    required String personKey,
  }) : this._(repository, personKey);

  PersonBalanceDetailNotifier._(this._repository, this._personKey)
    : super(const PersonBalanceDetailState()) {
    load();
  }

  Future<void> load() async {
    state = const PersonBalanceDetailState();

    try {
      final detail = await _repository.getPersonDetail(_personKey);
      if (!mounted) return;

      state = PersonBalanceDetailState(
        detail: detail,
        loadStatus: PersonBalanceDetailLoadStatus.success,
      );
    } catch (_) {
      if (!mounted) return;
      state = const PersonBalanceDetailState(
        loadStatus: PersonBalanceDetailLoadStatus.error,
      );
    }
  }

  Future<void> reload() => load();
}
