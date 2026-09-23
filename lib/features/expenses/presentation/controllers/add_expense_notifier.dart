import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../events/domain/event_participant.dart';
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

    _replaceState(totalAmountCents: totalAmountCents, payerDrafts: payerDrafts);
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

  void _replaceState({
    String? description,
    int? totalAmountCents,
    List<ExpensePayerDraft>? payerDrafts,
  }) {
    final resolvedPayerDrafts = payerDrafts ?? state.payerDrafts;
    final payersTotalCents = resolvedPayerDrafts.fold<int>(
      0,
      (sum, payer) => sum + payer.amountCents,
    );
    final resolvedTotalAmountCents = totalAmountCents ?? state.totalAmountCents;

    state = AddExpenseState(
      participants: _participants,
      description: description ?? state.description,
      totalAmountCents: resolvedTotalAmountCents,
      payerDrafts: resolvedPayerDrafts,
      payersTotalCents: payersTotalCents,
      differenceCents: resolvedTotalAmountCents - payersTotalCents,
    );
  }
}
