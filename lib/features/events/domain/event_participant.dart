class EventParticipant {
  final String eventId;
  final String? userId;
  final String username;
  final bool isAnonymous;
  final bool isOrganizer;

  const EventParticipant({
    required this.eventId,
    required this.userId,
    required this.username,
    required this.isAnonymous,
    required this.isOrganizer,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is EventParticipant &&
              runtimeType == other.runtimeType &&
              eventId == other.eventId &&
              userId == other.userId &&
              username == other.username &&
              isAnonymous == other.isAnonymous &&
              isOrganizer == other.isOrganizer;

  @override
  int get hashCode =>
      eventId.hashCode ^
      userId.hashCode ^
      username.hashCode ^
      isAnonymous.hashCode ^
      isOrganizer.hashCode;

  @override
  String toString() {
    return 'EventParticipant(eventId: $eventId, userId: $userId, username: $username, isAnonymous: $isAnonymous, isOrganizer: $isOrganizer)';
  }
}