import 'debt_status.dart';

// Una deuda concreta entre dos participantes dentro de un único evento.
class EventDebt {
  final String id;
  final String eventId;
  final String debtorParticipantId;
  final String debtorName;
  final String creditorParticipantId;
  final String creditorName;
  final int amountCents;
  final DebtStatus status;
  final DateTime? settledAt;

  const EventDebt({
    required this.id,
    required this.eventId,
    required this.debtorParticipantId,
    required this.debtorName,
    required this.creditorParticipantId,
    required this.creditorName,
    required this.amountCents,
    required this.status,
    this.settledAt,
  });

  EventDebt copyWith({
    String? id,
    String? eventId,
    String? debtorParticipantId,
    String? debtorName,
    String? creditorParticipantId,
    String? creditorName,
    int? amountCents,
    DebtStatus? status,
    DateTime? settledAt,
  }) {
    return EventDebt(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      debtorParticipantId: debtorParticipantId ?? this.debtorParticipantId,
      debtorName: debtorName ?? this.debtorName,
      creditorParticipantId:
          creditorParticipantId ?? this.creditorParticipantId,
      creditorName: creditorName ?? this.creditorName,
      amountCents: amountCents ?? this.amountCents,
      status: status ?? this.status,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventDebt &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          eventId == other.eventId &&
          debtorParticipantId == other.debtorParticipantId &&
          debtorName == other.debtorName &&
          creditorParticipantId == other.creditorParticipantId &&
          creditorName == other.creditorName &&
          amountCents == other.amountCents &&
          status == other.status &&
          settledAt == other.settledAt;

  @override
  int get hashCode =>
      id.hashCode ^
      eventId.hashCode ^
      debtorParticipantId.hashCode ^
      debtorName.hashCode ^
      creditorParticipantId.hashCode ^
      creditorName.hashCode ^
      amountCents.hashCode ^
      status.hashCode ^
      settledAt.hashCode;

  @override
  String toString() {
    return 'EventDebt(id: $id, eventId: $eventId, debtorParticipantId: $debtorParticipantId, debtorName: $debtorName, creditorParticipantId: $creditorParticipantId, creditorName: $creditorName, amountCents: $amountCents, status: $status, settledAt: $settledAt)';
  }
}
