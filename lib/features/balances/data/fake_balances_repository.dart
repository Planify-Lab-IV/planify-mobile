import '../domain/balance_summary.dart';
import '../domain/balance_direction.dart';
import '../domain/balances_repository.dart';
import '../domain/event_balance_line.dart';
import '../domain/person_balance.dart';
import '../domain/person_balance_detail.dart';
import '../domain/person_balance_status.dart';

// Repositorio temporal
class FakeBalancesRepository implements BalancesRepository {
  final Duration delay;
  bool shouldThrowError;
  final BalanceSummary _summary;
  final List<PersonBalance> _people;
  final Map<String, PersonBalanceDetail> _personDetails;

  FakeBalancesRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
    BalanceSummary? initialSummary,
    List<PersonBalance>? initialPeople,
    Map<String, PersonBalanceDetail>? initialPersonDetails,
  }) : _summary = initialSummary ?? _defaultSummary,
       _people = List<PersonBalance>.unmodifiable(
         initialPeople ?? _defaultPeople,
       ),
       _personDetails = Map<String, PersonBalanceDetail>.unmodifiable(
         initialPersonDetails ?? _defaultPersonDetails,
       );

  @override
  Future<BalanceSummary> getSummary() async {
    await _waitOrThrow();
    return _summary;
  }

  @override
  Future<List<PersonBalance>> listPeople() async {
    await _waitOrThrow();
    return List<PersonBalance>.unmodifiable(_people);
  }

  @override
  Future<PersonBalanceDetail> getPersonDetail(String personKey) async {
    await _waitOrThrow();
    final detail = _personDetails[personKey];
    if (detail == null) {
      throw Exception('Could not find balance detail for $personKey');
    }
    return detail;
  }

  Future<void> _waitOrThrow() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldThrowError) {
      throw Exception('Could not load balances');
    }
  }

  static const BalanceSummary _defaultSummary = BalanceSummary(
    owedToMeCents: 82500,
    iOweCents: 24300,
  );

  static const List<PersonBalance> _defaultPeople = [
    PersonBalance(
      personKey: 'user:ana',
      displayName: 'Ana',
      status: PersonBalanceStatus.pay,
      netCents: -24300,
    ),
    PersonBalance(
      personKey: 'participant:martin',
      displayName: 'Martín',
      status: PersonBalanceStatus.pending,
      netCents: 82500,
    ),
    PersonBalance(
      personKey: 'user:sol',
      displayName: 'Sol',
      status: PersonBalanceStatus.settled,
      netCents: 0,
    ),
  ];

  static final Map<String, PersonBalanceDetail> _defaultPersonDetails = {
    'user:ana': PersonBalanceDetail(
      personKey: 'user:ana',
      displayName: 'Ana',
      status: PersonBalanceStatus.pay,
      netCents: -24300,
      breakdown: const [
        EventBalanceLine(
          eventId: 'event:asado',
          eventName: 'Asado',
          amountCents: 50000,
          direction: BalanceDirection.iOwe,
        ),
        EventBalanceLine(
          eventId: 'event:cine',
          eventName: 'Cine',
          amountCents: 25700,
          direction: BalanceDirection.owedToMe,
        ),
      ],
    ),
    'participant:martin': PersonBalanceDetail(
      personKey: 'participant:martin',
      displayName: 'Martín',
      status: PersonBalanceStatus.pending,
      netCents: 82500,
      breakdown: const [
        EventBalanceLine(
          eventId: 'event:viaje',
          eventName: 'Viaje',
          amountCents: 82500,
          direction: BalanceDirection.owedToMe,
        ),
      ],
    ),
    'user:sol': PersonBalanceDetail(
      personKey: 'user:sol',
      displayName: 'Sol',
      status: PersonBalanceStatus.settled,
      netCents: 0,
      breakdown: const [
        EventBalanceLine(
          eventId: 'event:picnic',
          eventName: 'Picnic',
          amountCents: 12000,
          direction: BalanceDirection.iOwe,
        ),
        EventBalanceLine(
          eventId: 'event:merienda',
          eventName: 'Merienda',
          amountCents: 12000,
          direction: BalanceDirection.owedToMe,
        ),
      ],
    ),
  };
}
