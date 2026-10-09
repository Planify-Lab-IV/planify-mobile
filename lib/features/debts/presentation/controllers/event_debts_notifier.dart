import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/debts_repository.dart';
import '../../domain/debt_settlement.dart';
import '../../domain/debt_status.dart';
import 'event_debts_state.dart';

typedef EventDebtFixturePreparer =
    bool Function({
      required String eventId,
      required String eventName,
      required String currentParticipantId,
      required String counterpartyParticipantId,
      required String counterpartyPersonKey,
      required String counterpartyName,
    });

class EventDebtsNotifier extends StateNotifier<EventDebtsState> {
  final DebtsRepository repository;
  final String eventId;
  final void Function()? onSettled;
  final void Function()? onFixturePrepared;
  final EventDebtFixturePreparer? prepareFixture;
  int _loadVersion = 0;
  String? _preparedFixtureKey;

  EventDebtsNotifier({
    required this.repository,
    required this.eventId,
    this.onSettled,
    this.onFixturePrepared,
    this.prepareFixture,
  }) : super(const EventDebtsState()) {
    load();
  }

  Future<void> load({bool silent = false}) async {
    final version = ++_loadVersion;
    final preserve = silent && state.isSuccess;
    state = state.copyWith(
      isRefreshing: preserve,
      loadStatus: preserve ? state.loadStatus : EventDebtsLoadStatus.loading,
    );

    try {
      final eventDebts = await repository.listEventDebts(eventId);
      if (!mounted || version != _loadVersion) return;
      state = state.copyWith(
        eventDebts: eventDebts,
        loadStatus: EventDebtsLoadStatus.success,
        isRefreshing: false,
      );
    } catch (_) {
      if (!mounted || version != _loadVersion) return;
      state = state.copyWith(
        isRefreshing: false,
        loadStatus: preserve
            ? EventDebtsLoadStatus.success
            : EventDebtsLoadStatus.error,
      );
    }
  }

  Future<void> reload({bool silent = false}) => load(silent: silent);

  Future<void> prepareEventFixture({
    required String eventName,
    required String currentParticipantId,
    required String counterpartyParticipantId,
    required String counterpartyPersonKey,
    required String counterpartyName,
  }) async {
    final fixtureKey = [
      eventId,
      currentParticipantId,
      counterpartyParticipantId,
    ].join('|');
    if (_preparedFixtureKey == fixtureKey || prepareFixture == null) return;
    _preparedFixtureKey = fixtureKey;
    final changed = prepareFixture!(
      eventId: eventId,
      eventName: eventName,
      currentParticipantId: currentParticipantId,
      counterpartyParticipantId: counterpartyParticipantId,
      counterpartyPersonKey: counterpartyPersonKey,
      counterpartyName: counterpartyName,
    );
    if (changed) {
      onFixturePrepared?.call();
      await reload(silent: state.isSuccess);
    }
  }

  Future<DebtSettlementResult> settleDebt(
    String debtId,
    String? participantId,
  ) async {
    if (state.isSettling || state.isRefreshing) {
      return DebtSettlementResult.ignored;
    }
    final matches = state.eventDebts.debts.where((debt) => debt.id == debtId);
    if (matches.isEmpty) return DebtSettlementResult.notFound;
    if (matches.first.status.isSettled) {
      return DebtSettlementResult.alreadySettled;
    }
    if (!canSettleDebt(matches.first, participantId)) {
      return DebtSettlementResult.forbidden;
    }
    state = state.copyWith(isSettling: true);
    try {
      await repository.settleDebt(eventId, debtId);
      if (!mounted) return DebtSettlementResult.ignored;
      // Prevent a pre-mutation read from overwriting the local settled row.
      _loadVersion++;
      final debts = [
        for (final debt in state.eventDebts.debts)
          if (debt.id == debtId)
            debt.copyWith(status: DebtStatus.settled, settledAt: DateTime.now())
          else
            debt,
      ];
      state = state.copyWith(
        eventDebts: state.eventDebts.copyWith(
          debts: List.unmodifiable(debts),
          allSettled: debts.every((d) => d.status.isSettled),
        ),
      );
      onSettled?.call();
      return DebtSettlementResult.success;
    } catch (error) {
      final result = settlementError(error);
      if (mounted && result == DebtSettlementResult.alreadySettled) {
        await reload(silent: true);
        if (mounted) onSettled?.call();
      }
      return result;
    } finally {
      if (mounted) state = state.copyWith(isSettling: false);
    }
  }
}
