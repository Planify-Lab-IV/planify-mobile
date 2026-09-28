import 'balance_summary.dart';
import 'person_balance.dart';
import 'person_balance_detail.dart';

// Contrato para obtener los saldos globales de la persona autenticada y sus detalles.
abstract interface class BalancesRepository {
  Future<BalanceSummary> getSummary();

  Future<List<PersonBalance>> listPeople();

  Future<PersonBalanceDetail> getPersonDetail(String personKey);
}
