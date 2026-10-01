import 'balance_summary.dart';
import 'person_balance.dart';

// Contrato para obtener los saldos globales de la persona autenticada.
abstract interface class BalancesRepository {
  Future<BalanceSummary> getSummary();

  Future<List<PersonBalance>> listPeople();
}
