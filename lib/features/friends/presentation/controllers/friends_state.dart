import 'package:flutter/foundation.dart';

import '../../domain/friend_requests.dart';
import '../../domain/person.dart';

enum FriendsLoadStatus { idle, loading, success, error }

enum FriendActionResult { success, ignored, failure, requestUnavailable }

class FriendsState {
  final String searchQuery;
  final List<Person> searchResults;
  final FriendsLoadStatus searchStatus;
  final FriendRequests requests;
  final FriendsLoadStatus requestsStatus;
  final List<Person> friends;
  final FriendsLoadStatus friendsStatus;
  final Set<String> pendingPersonIds;

  FriendsState({
    this.searchQuery = '',
    List<Person> searchResults = const [],
    this.searchStatus = FriendsLoadStatus.idle,
    FriendRequests? requests,
    this.requestsStatus = FriendsLoadStatus.loading,
    List<Person> friends = const [],
    this.friendsStatus = FriendsLoadStatus.loading,
    Set<String> pendingPersonIds = const {},
  }) : searchResults = List.unmodifiable(searchResults),
       requests = requests ?? FriendRequests(),
       friends = List.unmodifiable(friends),
       pendingPersonIds = Set.unmodifiable(pendingPersonIds);

  bool get isSearchActive => searchQuery.trim().length >= 2;

  bool isPending(Person person) => pendingPersonIds.contains(person.id);

  FriendsState copyWith({
    String? searchQuery,
    List<Person>? searchResults,
    FriendsLoadStatus? searchStatus,
    FriendRequests? requests,
    FriendsLoadStatus? requestsStatus,
    List<Person>? friends,
    FriendsLoadStatus? friendsStatus,
    Set<String>? pendingPersonIds,
  }) {
    return FriendsState(
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      searchStatus: searchStatus ?? this.searchStatus,
      requests: requests ?? this.requests,
      requestsStatus: requestsStatus ?? this.requestsStatus,
      friends: friends ?? this.friends,
      friendsStatus: friendsStatus ?? this.friendsStatus,
      pendingPersonIds: pendingPersonIds ?? this.pendingPersonIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendsState &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          listEquals(searchResults, other.searchResults) &&
          searchStatus == other.searchStatus &&
          requests == other.requests &&
          requestsStatus == other.requestsStatus &&
          listEquals(friends, other.friends) &&
          friendsStatus == other.friendsStatus &&
          setEquals(pendingPersonIds, other.pendingPersonIds);

  @override
  int get hashCode => Object.hash(
    searchQuery,
    Object.hashAll(searchResults),
    searchStatus,
    requests,
    requestsStatus,
    Object.hashAll(friends),
    friendsStatus,
    Object.hashAll(pendingPersonIds),
  );
}
