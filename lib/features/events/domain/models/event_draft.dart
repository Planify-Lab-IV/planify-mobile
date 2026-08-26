import 'package:flutter/material.dart';

class EventDraft {
  // Paso 1: Información básica
  final String name;
  final String location;

  // Pasos futuros (fecha, hora, detalles adicionales)
  final DateTime? date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? description;

  const EventDraft({
    this.name = '',
    this.location = '',
    this.date,
    this.startTime,
    this.endTime,
    this.description,
  });

  const EventDraft.empty() : this();

  bool get isEmpty =>
      name.trim().isEmpty &&
      location.trim().isEmpty &&
      date == null &&
      startTime == null &&
      endTime == null &&
      (description == null || description!.trim().isEmpty);

  bool get isStep1Valid =>
      name.trim().isNotEmpty && location.trim().isNotEmpty;

  EventDraft copyWith({
    String? name,
    String? location,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? description,
  }) {
    return EventDraft(
      name: name ?? this.name,
      location: location ?? this.location,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventDraft &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          location == other.location &&
          date == other.date &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          description == other.description;

  @override
  int get hashCode =>
      name.hashCode ^
      location.hashCode ^
      date.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      description.hashCode;

  @override
  String toString() {
    return 'EventDraft(name: $name, location: $location, date: $date, startTime: $startTime, endTime: $endTime)';
  }
}
