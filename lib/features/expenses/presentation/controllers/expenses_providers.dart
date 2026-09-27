import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../events/domain/event_participant.dart';
import '../../data/fake_expenses_repository.dart';
import '../../domain/expenses_repository.dart';
import 'add_expense_notifier.dart';
import 'add_expense_state.dart';

// A reemplazar por un http expenses repository
final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return FakeExpensesRepository();
});

// Cada diálogo mantiene un borrador aislado para los participantes recibidos.
final addExpenseNotifierProvider = StateNotifierProvider.autoDispose
    .family<AddExpenseNotifier, AddExpenseState, List<EventParticipant>>((
      ref,
      participants,
    ) {
      return AddExpenseNotifier(participants: participants);
    });
