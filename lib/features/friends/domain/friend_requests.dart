import 'package:flutter/foundation.dart';

import 'friend_request.dart';

// Agrupa las solicitudes según su dirección respecto de la persona actual.
class FriendRequests {
  final List<FriendRequest> received;
  final List<FriendRequest> sent;

  FriendRequests({
    List<FriendRequest> received = const [],
    List<FriendRequest> sent = const [],
  }) : received = List.unmodifiable(received),
       sent = List.unmodifiable(sent);

  FriendRequests copyWith({
    List<FriendRequest>? received,
    List<FriendRequest>? sent,
  }) {
    return FriendRequests(
      received: received ?? this.received,
      sent: sent ?? this.sent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendRequests &&
          runtimeType == other.runtimeType &&
          listEquals(received, other.received) &&
          listEquals(sent, other.sent);

  @override
  int get hashCode => Object.hashAll(received) ^ Object.hashAll(sent);

  @override
  String toString() {
    return 'FriendRequests(received: $received, sent: $sent)';
  }
}
