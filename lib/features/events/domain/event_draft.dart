import 'package:flutter/material.dart';

class EventDraft {
  // informacion del paso 1
  final String name;
  final String location;

  // aca se agregaria la informacion de los proximos pasos


  const EventDraft({
    this.name = '',
    this.location = '',
  });

  const EventDraft.empty() : this();

  bool get isEmpty =>
      name.trim().isEmpty &&
      location.trim().isEmpty;

  bool get isStep1Valid => name.trim().isNotEmpty && location.trim().isNotEmpty;

  EventDraft copyWith({
    String? name,
    String? location,
  }) {
    return EventDraft(
      name: name ?? this.name,
      location: location ?? this.location,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventDraft &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          location == other.location;

  @override
  int get hashCode =>
      name.hashCode ^
      location.hashCode;

  @override
  String toString() {
    return 'EventDraft(name: $name, location: $location)';
  }
}
