import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/http_expenses_repository.dart';
import '../../domain/expenses_repository.dart';
import 'add_expense_notifier.dart';
import 'add_expense_state.dart';
import 'add_expense_context.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return HttpExpensesRepository(dio: ref.watch(dioClientProvider));
});

// Cada diálogo mantiene un borrador aislado para los participantes recibidos.
final addExpenseNotifierProvider = StateNotifierProvider.autoDispose
    .family<AddExpenseNotifier, AddExpenseState, AddExpenseContext>((
      ref,
      context,
    ) {
      return AddExpenseNotifier(
        participants: context.participants,
        eventId: context.eventId,
        repository: ref.watch(expensesRepositoryProvider),
      );
    });
