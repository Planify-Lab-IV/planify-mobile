import '../domain/balance_summary.dart';
import '../domain/balances_repository.dart';
import '../domain/person_balance.dart';
import '../domain/person_balance_status.dart';

// Repositorio temporal
class FakeBalancesRepository implements BalancesRepository {
  final Duration delay;
  bool shouldThrowError;
  final BalanceSummary _summary;
  final List<PersonBalance> _people;

  FakeBalancesRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
    BalanceSummary? initialSummary,
    List<PersonBalance>? initialPeople,
  }) : _summary = initialSummary ?? _defaultSummary,
       _people = List<PersonBalance>.unmodifiable(
         initialPeople ?? _defaultPeople,
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
      netCents: 24300,
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
}
