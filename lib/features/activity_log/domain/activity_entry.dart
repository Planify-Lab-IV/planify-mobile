import 'activity_type.dart';

// Entrada individual de la historia del evento
class ActivityEntry {
  final String id;
  final ActivityType type;
  final String actorParticipantId;
  final String actorUsername;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const ActivityEntry({
    required this.id,
    required this.type,
    required this.actorParticipantId,
    required this.actorUsername,
    required this.payload,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          actorParticipantId == other.actorParticipantId &&
          actorUsername == other.actorUsername &&
          _mapsEqual(payload, other.payload) &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    type,
    actorParticipantId,
    actorUsername,
    Object.hashAllUnordered(
      payload.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    createdAt,
  );

  @override
  String toString() {
    return 'ActivityEntry(id: $id, type: $type, actorParticipantId: '
        '$actorParticipantId, actorUsername: $actorUsername, payload: '
        '$payload, createdAt: $createdAt)';
  }

  static bool _mapsEqual(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    if (first.length != second.length) return false;

    for (final entry in first.entries) {
      if (!second.containsKey(entry.key) || second[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }
}
