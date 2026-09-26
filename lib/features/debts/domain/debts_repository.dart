import 'event_debts.dart';

// Contrato para consultar las deudas calculadas de un evento.
abstract interface class DebtsRepository {
  Future<EventDebts> listEventDebts(String eventId);
}
