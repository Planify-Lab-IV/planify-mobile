import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/balances_repository.dart';
import '../../../debts/domain/debts_repository.dart';
import '../../../debts/domain/debt_settlement.dart';
import 'person_balance_detail_state.dart';

class PersonBalanceDetailNotifier
    extends StateNotifier<PersonBalanceDetailState> {
  final BalancesRepository _repository;
  final String _personKey;
  final DebtsRepository? _debtsRepository;
  final void Function()? _onSettled;
  int _loadVersion = 0;

  PersonBalanceDetailNotifier({
    required BalancesRepository repository,
    required String personKey,
    DebtsRepository? debtsRepository,
    void Function()? onSettled,
  }) : this._(repository, personKey, debtsRepository, onSettled);

  PersonBalanceDetailNotifier._(
    this._repository,
    this._personKey,
    this._debtsRepository,
    this._onSettled,
  ) : super(const PersonBalanceDetailState()) {
    load();
  }

  Future<void> load({bool silent = false}) async {
    final version = ++_loadVersion;
    final preserve = silent && state.detail != null;
    if (!preserve) {
      state = state.copyWith(loadStatus: PersonBalanceDetailLoadStatus.loading);
    }

    try {
      final detail = await _repository.getPersonDetail(_personKey);
      if (!mounted || version != _loadVersion) return;

      state = state.copyWith(
        detail: detail,
        loadStatus: PersonBalanceDetailLoadStatus.success,
      );
    } catch (_) {
      if (!mounted || version != _loadVersion) return;
      if (!preserve) {
        state = state.copyWith(loadStatus: PersonBalanceDetailLoadStatus.error);
      }
    }
  }

  Future<void> reload({bool silent = false}) => load(silent: silent);

  Future<DebtSettlementResult> settleWithPerson() async {
    if (state.isSettling || state.detail == null) {
      return DebtSettlementResult.ignored;
    }
    if (state.detail!.status.isSettled) {
      return DebtSettlementResult.alreadySettled;
    }
    if (_debtsRepository == null) return DebtSettlementResult.failure;
    state = state.copyWith(isSettling: true);
    var result = DebtSettlementResult.success;
    try {
      await _debtsRepository.settleWithPerson(_personKey);
    } catch (error) {
      result = settlementError(error);
    }
    if (!mounted) return DebtSettlementResult.ignored;
    if (result.succeeded) {
      _onSettled?.call();
      await reload(silent: true);
    }
    if (mounted) state = state.copyWith(isSettling: false);
    return result;
  }
}
