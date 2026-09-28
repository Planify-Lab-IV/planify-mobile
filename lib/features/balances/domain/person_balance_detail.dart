import 'event_balance_line.dart';
import 'person_balance_status.dart';

// Saldo agregado con una persona y los eventos que componen ese neto.
class PersonBalanceDetail {
  final String personKey;
  final String displayName;
  final PersonBalanceStatus status;
  final int netCents;
  final List<EventBalanceLine> breakdown;

  PersonBalanceDetail({
    required this.personKey,
    required this.displayName,
    required this.status,
    required this.netCents,
    required List<EventBalanceLine> breakdown,
  }) : breakdown = List<EventBalanceLine>.unmodifiable(breakdown);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonBalanceDetail &&
          runtimeType == other.runtimeType &&
          personKey == other.personKey &&
          displayName == other.displayName &&
          status == other.status &&
          netCents == other.netCents &&
          _sameBreakdown(breakdown, other.breakdown);

  @override
  int get hashCode => Object.hash(
    personKey,
    displayName,
    status,
    netCents,
    Object.hashAll(breakdown),
  );

  @override
  String toString() {
    return 'PersonBalanceDetail(personKey: $personKey, displayName: $displayName, status: $status, netCents: $netCents, breakdown: $breakdown)';
  }
}

bool _sameBreakdown(
  List<EventBalanceLine> left,
  List<EventBalanceLine> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
