// Importe que un participante seleccionado aportara a un gasto de edicion
class ExpensePayerDraft {
  final String participantId;
  final int amountCents;

  const ExpensePayerDraft({
    required this.participantId,
    required this.amountCents,
  });

  ExpensePayerDraft copyWith({String? participantId, int? amountCents}) {
    return ExpensePayerDraft(
      participantId: participantId ?? this.participantId,
      amountCents: amountCents ?? this.amountCents,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpensePayerDraft &&
          runtimeType == other.runtimeType &&
          participantId == other.participantId &&
          amountCents == other.amountCents;

  @override
  int get hashCode => participantId.hashCode ^ amountCents.hashCode;

  @override
  String toString() {
    return 'ExpensePayerDraft(participantId: $participantId, amountCents: $amountCents)';
  }
}
