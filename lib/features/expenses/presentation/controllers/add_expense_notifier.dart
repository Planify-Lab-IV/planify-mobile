import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../events/domain/event_participant.dart';
import '../../domain/expense_debtor_draft.dart';
import '../../domain/expense_payer_draft.dart';
import '../../domain/split_evenly.dart';
import 'add_expense_state.dart';

// Maneja el borrador del gasto mientras el dialogo está abierto
class AddExpenseNotifier extends StateNotifier<AddExpenseState> {
  final List<EventParticipant> _participants;

  AddExpenseNotifier({required List<EventParticipant> participants})
    : _participants = List<EventParticipant>.unmodifiable(participants),
      super(AddExpenseState(participants: participants));

  void setDescription(String description) {
    _replaceState(description: description.trim());
  }

  void setTotalAmountCents(int totalAmountCents) {
    if (totalAmountCents < 0) {
      throw ArgumentError.value(
        totalAmountCents,
        'totalAmountCents',
        'must not be negative',
      );
    }

    var payerDrafts = state.payerDrafts;
    if (payerDrafts.length == 1) {
      payerDrafts = [
        payerDrafts.single.copyWith(amountCents: totalAmountCents),
      ];
    }

    var debtorDrafts = state.debtorDrafts;
    if (debtorDrafts.length == 1) {
      debtorDrafts = [
        debtorDrafts.single.copyWith(amountCents: totalAmountCents),
      ];
    }

    _replaceState(
      totalAmountCents: totalAmountCents,
      payerDrafts: payerDrafts,
      debtorDrafts: debtorDrafts,
    );
  }

  void togglePayer(String participantId) {
    _ensureKnownParticipant(participantId);

    final payerDrafts = List<ExpensePayerDraft>.from(state.payerDrafts);
    final payerIndex = payerDrafts.indexWhere(
      (payer) => payer.participantId == participantId,
    );
    if (payerIndex == -1) {
      payerDrafts.add(
        ExpensePayerDraft(
          participantId: participantId,
          amountCents: state.totalAmountCents,
        ),
      );
    } else {
      payerDrafts.removeAt(payerIndex);
    }

    _replaceState(payerDrafts: _withSinglePayerTotal(payerDrafts));
  }

  void setPayerAmount(String participantId, int amountCents) {
    if (amountCents < 0) {
      throw ArgumentError.value(
        amountCents,
        'amountCents',
        'must not be negative',
      );
    }
    if (state.payerDrafts.length <= 1) return;

    final payerIndex = state.payerDrafts.indexWhere(
      (payer) => payer.participantId == participantId,
    );
    if (payerIndex == -1) {
      throw ArgumentError.value(
        participantId,
        'participantId',
        'is not a payer',
      );
    }

    final payerDrafts = List<ExpensePayerDraft>.from(state.payerDrafts);
    payerDrafts[payerIndex] = payerDrafts[payerIndex].copyWith(
      amountCents: amountCents,
    );
    _replaceState(payerDrafts: payerDrafts);
  }

  void splitPayersEvenly() {
    if (state.payerDrafts.isEmpty) return;

    final splitAmounts = splitEvenly(
      state.totalAmountCents,
      state.payerDrafts.length,
    );
    final payerDrafts = [
      for (var index = 0; index < state.payerDrafts.length; index++)
        state.payerDrafts[index].copyWith(amountCents: splitAmounts[index]),
    ];
    _replaceState(payerDrafts: payerDrafts);
  }

  // Agrega o quita un participante de la lista de deudores
  void toggleDebtor(String participantId) {
    _ensureKnownParticipant(participantId);

    final debtorDrafts = List<ExpenseDebtorDraft>.from(state.debtorDrafts);
    final debtorIndex = debtorDrafts.indexWhere(
      (debtor) => debtor.participantId == participantId,
    );
    if (debtorIndex == -1) {
      debtorDrafts.add(
        ExpenseDebtorDraft(
          participantId: participantId,
          amountCents: state.totalAmountCents,
        ),
      );
    } else {
      debtorDrafts.removeAt(debtorIndex);
    }

    _replaceState(debtorDrafts: _withSingleDebtorTotal(debtorDrafts));
  }

  // Permite modificar cuando debe alguien cuando hay 2 o mas deudores
  void setDebtorAmount(String participantId, int amountCents) {
    if (amountCents < 0) {
      throw ArgumentError.value(
        amountCents,
        'amountCents',
        'must not be negative',
      );
    }
    if (state.debtorDrafts.length <= 1) return;

    final debtorIndex = state.debtorDrafts.indexWhere(
      (debtor) => debtor.participantId == participantId,
    );
    if (debtorIndex == -1) {
      throw ArgumentError.value(
        participantId,
        'participantId',
        'is not a debtor',
      );
    }

    final debtorDrafts = List<ExpenseDebtorDraft>.from(state.debtorDrafts);
    debtorDrafts[debtorIndex] = debtorDrafts[debtorIndex].copyWith(
      amountCents: amountCents,
    );
    _replaceState(debtorDrafts: debtorDrafts);
  }

  void splitDebtorsEvenly() {
    if (state.debtorDrafts.isEmpty) return;

    final splitAmounts = splitEvenly(
      state.totalAmountCents,
      state.debtorDrafts.length,
    );
    final debtorDrafts = [
      for (var index = 0; index < state.debtorDrafts.length; index++)
        state.debtorDrafts[index].copyWith(amountCents: splitAmounts[index]),
    ];
    _replaceState(debtorDrafts: debtorDrafts);
  }

  /// Simula el guardado hasta que exista la persistencia real de gastos.
  Future<bool> save() async {
    if (!state.isReadyForSubmission || state.isSaving) return false;

    state = state.copyWith(saveStatus: ExpenseSaveStatus.saving);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(saveStatus: ExpenseSaveStatus.success);
    return true;
  }

  void _ensureKnownParticipant(String participantId) {
    final isKnownParticipant = _participants.any(
      (participant) => participant.id == participantId,
    );
    if (!isKnownParticipant) {
      throw ArgumentError.value(
        participantId,
        'participantId',
        'does not belong to this event',
      );
    }
  }

  List<ExpensePayerDraft> _withSinglePayerTotal(
    List<ExpensePayerDraft> payerDrafts,
  ) {
    if (payerDrafts.length != 1) return payerDrafts;

    return [payerDrafts.single.copyWith(amountCents: state.totalAmountCents)];
  }

  // Regla de si hay un solo deudor el monto debe ser el total
  List<ExpenseDebtorDraft> _withSingleDebtorTotal(
    List<ExpenseDebtorDraft> debtorDrafts,
  ) {
    if (debtorDrafts.length != 1) return debtorDrafts;

    return [debtorDrafts.single.copyWith(amountCents: state.totalAmountCents)];
  }

  void _replaceState({
    String? description,
    int? totalAmountCents,
    List<ExpensePayerDraft>? payerDrafts,
    List<ExpenseDebtorDraft>? debtorDrafts,
  }) {
    final resolvedPayerDrafts = payerDrafts ?? state.payerDrafts;
    final payersTotalCents = resolvedPayerDrafts.fold<int>(
      0,
      (sum, payer) => sum + payer.amountCents,
    );
    final resolvedDebtorDrafts = debtorDrafts ?? state.debtorDrafts;
    final debtorsTotalCents = resolvedDebtorDrafts.fold<int>(
      0,
      (sum, debtor) => sum + debtor.amountCents,
    );
    final resolvedTotalAmountCents = totalAmountCents ?? state.totalAmountCents;

    state = AddExpenseState(
      participants: _participants,
      description: description ?? state.description,
      totalAmountCents: resolvedTotalAmountCents,
      payerDrafts: resolvedPayerDrafts,
      payersTotalCents: payersTotalCents,
      differenceCents: resolvedTotalAmountCents - payersTotalCents,
      debtorDrafts: resolvedDebtorDrafts,
      debtorsTotalCents: debtorsTotalCents,
      debtorDifferenceCents: resolvedTotalAmountCents - debtorsTotalCents,
      saveStatus: state.saveStatus,
    );
  }
}
