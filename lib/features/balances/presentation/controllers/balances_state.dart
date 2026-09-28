import '../../domain/balance_summary.dart';
import '../../domain/person_balance.dart';

enum BalancesLoadStatus { loading, success, error }

// Estado de presentación de la consulta conjunta del resumen y las personas.
class BalancesState {
  final BalanceSummary summary;
  final List<PersonBalance> people;
  final BalancesLoadStatus loadStatus;

  const BalancesState({
    this.summary = const BalanceSummary(owedToMeCents: 0, iOweCents: 0),
    this.people = const [],
    this.loadStatus = BalancesLoadStatus.loading,
  });

  bool get isLoading => loadStatus == BalancesLoadStatus.loading;
  bool get isSuccess => loadStatus == BalancesLoadStatus.success;
  bool get hasLoadError => loadStatus == BalancesLoadStatus.error;
  bool get isEmpty => isSuccess && people.isEmpty;

  BalancesState copyWith({
    BalanceSummary? summary,
    List<PersonBalance>? people,
    BalancesLoadStatus? loadStatus,
  }) {
    return BalancesState(
      summary: summary ?? this.summary,
      people: people ?? this.people,
      loadStatus: loadStatus ?? this.loadStatus,
    );
  }
}
