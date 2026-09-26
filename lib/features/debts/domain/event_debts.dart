import 'package:flutter/foundation.dart';

import 'event_debt.dart';

// Resumen de las deudas que pertenecen a un evento.
class EventDebts {
  final List<EventDebt> debts;
  final bool allSettled;

  const EventDebts({required this.debts, required this.allSettled});

  EventDebts copyWith({List<EventDebt>? debts, bool? allSettled}) {
    return EventDebts(
      debts: debts ?? this.debts,
      allSettled: allSettled ?? this.allSettled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventDebts &&
          runtimeType == other.runtimeType &&
          listEquals(debts, other.debts) &&
          allSettled == other.allSettled;

  @override
  int get hashCode => Object.hashAll(debts) ^ allSettled.hashCode;

  @override
  String toString() {
    return 'EventDebts(debts: $debts, allSettled: $allSettled)';
  }
}
