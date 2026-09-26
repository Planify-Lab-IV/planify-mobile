import '../domain/debt_status.dart';
import '../domain/debts_repository.dart';
import '../domain/event_debt.dart';
import '../domain/event_debts.dart';

// Simula la respuesta de deudas calculadas
class FakeDebtsRepository implements DebtsRepository {
  final Duration delay;
  final bool shouldThrowError;
  final Map<String, EventDebts> _debtsByEventId;

  FakeDebtsRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
    Map<String, EventDebts>? initialEventDebts,
  }) : _debtsByEventId = Map<String, EventDebts>.from(
         initialEventDebts ?? _defaultEventDebts,
       );

  @override
  Future<EventDebts> listEventDebts(String eventId) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldThrowError) {
      throw Exception('Could not load event debts');
    }

    return _debtsByEventId[eventId] ??
        const EventDebts(debts: [], allSettled: false);
  }

  static final Map<String, EventDebts> _defaultEventDebts = {
    'evt-123': EventDebts(
      allSettled: false,
      debts: [
        const EventDebt(
          id: 'debt-evt-123-1',
          eventId: 'evt-123',
          debtorParticipantId: 'participant-member-evt-123',
          debtorName: 'Ana',
          creditorParticipantId: 'participant-org-evt-123',
          creditorName: 'Lucía',
          amountCents: 50000,
          status: DebtStatus.pending,
        ),
        const EventDebt(
          id: 'debt-evt-123-2',
          eventId: 'evt-123',
          debtorParticipantId: 'participant-anon-evt-123',
          debtorName: 'Juan',
          creditorParticipantId: 'participant-member-evt-123',
          creditorName: 'Ana',
          amountCents: 12500,
          status: DebtStatus.pending,
        ),
        EventDebt(
          id: 'debt-evt-123-3',
          eventId: 'evt-123',
          debtorParticipantId: 'participant-member-evt-123',
          debtorName: 'Ana',
          creditorParticipantId: 'participant-anon-evt-123',
          creditorName: 'Juan',
          amountCents: 25000,
          status: DebtStatus.settled,
          settledAt: DateTime(2026, 1, 2),
        ),
      ],
    ),
    'evt-cumple-lucas': EventDebts(
      allSettled: true,
      debts: [
        EventDebt(
          id: 'debt-evt-cumple-lucas-1',
          eventId: 'evt-cumple-lucas',
          debtorParticipantId: 'participant-member-evt-cumple-lucas',
          debtorName: 'Ana',
          creditorParticipantId: 'participant-org-evt-cumple-lucas',
          creditorName: 'Lucía',
          amountCents: 18000,
          status: DebtStatus.settled,
          settledAt: DateTime(2026, 1, 3),
        ),
      ],
    ),
    'evt-fake-demo': const EventDebts(debts: [], allSettled: false),
  };
}
