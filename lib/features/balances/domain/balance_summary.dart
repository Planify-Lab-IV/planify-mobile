// Resumen de los saldos de la persona autenticada en toda la aplicación.
class BalanceSummary {
  final int owedToMeCents;
  final int iOweCents;

  const BalanceSummary({
    required this.owedToMeCents,
    required this.iOweCents,
  });

  BalanceSummary copyWith({int? owedToMeCents, int? iOweCents}) {
    return BalanceSummary(
      owedToMeCents: owedToMeCents ?? this.owedToMeCents,
      iOweCents: iOweCents ?? this.iOweCents,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BalanceSummary &&
          runtimeType == other.runtimeType &&
          owedToMeCents == other.owedToMeCents &&
          iOweCents == other.iOweCents;

  @override
  int get hashCode => owedToMeCents.hashCode ^ iOweCents.hashCode;

  @override
  String toString() {
    return 'BalanceSummary(owedToMeCents: $owedToMeCents, iOweCents: $iOweCents)';
  }
}
