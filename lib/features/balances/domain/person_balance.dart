import 'person_balance_status.dart';

// Saldo agregado entre la persona autenticada y otra persona.
// [personKey] es opaco para la app
class PersonBalance {
  final String personKey;
  final String displayName;
  final PersonBalanceStatus status;
  final int netCents;

  const PersonBalance({
    required this.personKey,
    required this.displayName,
    required this.status,
    required this.netCents,
  });

  PersonBalance copyWith({
    String? personKey,
    String? displayName,
    PersonBalanceStatus? status,
    int? netCents,
  }) {
    return PersonBalance(
      personKey: personKey ?? this.personKey,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      netCents: netCents ?? this.netCents,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonBalance &&
          runtimeType == other.runtimeType &&
          personKey == other.personKey &&
          displayName == other.displayName &&
          status == other.status &&
          netCents == other.netCents;

  @override
  int get hashCode =>
      personKey.hashCode ^
      displayName.hashCode ^
      status.hashCode ^
      netCents.hashCode;

  @override
  String toString() {
    return 'PersonBalance(personKey: $personKey, displayName: $displayName, status: $status, netCents: $netCents)';
  }
}
