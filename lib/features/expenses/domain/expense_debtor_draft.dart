// Importe que un participante debe asumir dentro de un gasto en edición.
class ExpenseDebtorDraft {
  final String participantId;
  final int amountCents;

  const ExpenseDebtorDraft({
    required this.participantId,
    required this.amountCents,
  });

  ExpenseDebtorDraft copyWith({String? participantId, int? amountCents}) {
    return ExpenseDebtorDraft(
      participantId: participantId ?? this.participantId,
      amountCents: amountCents ?? this.amountCents,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseDebtorDraft &&
          runtimeType == other.runtimeType &&
          participantId == other.participantId &&
          amountCents == other.amountCents;

  @override
  int get hashCode => participantId.hashCode ^ amountCents.hashCode;

  @override
  String toString() {
    return 'ExpenseDebtorDraft(participantId: $participantId, amountCents: $amountCents)';
  }
}
