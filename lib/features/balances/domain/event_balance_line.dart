import 'balance_direction.dart';

// Aporte de un evento al saldo entre la persona autenticada y otra persona.
class EventBalanceLine {
  final String eventId;
  final String eventName;
  final int amountCents;
  final BalanceDirection direction;

  const EventBalanceLine({
    required this.eventId,
    required this.eventName,
    required this.amountCents,
    required this.direction,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventBalanceLine &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          eventName == other.eventName &&
          amountCents == other.amountCents &&
          direction == other.direction;

  @override
  int get hashCode =>
      eventId.hashCode ^
      eventName.hashCode ^
      amountCents.hashCode ^
      direction.hashCode;

  @override
  String toString() {
    return 'EventBalanceLine(eventId: $eventId, eventName: $eventName, amountCents: $amountCents, direction: $direction)';
  }
}
