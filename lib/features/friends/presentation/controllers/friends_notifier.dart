import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/friends_exceptions.dart';
import '../../domain/friend_requests.dart';
import '../../domain/friends_repository.dart';
import '../../domain/person.dart';
import 'friends_state.dart';

class FriendsNotifier extends StateNotifier<FriendsState> {
  final FriendsRepository repository;
  final Duration searchDebounce;

  Timer? _searchTimer;
  var _searchVersion = 0;
  var _requestsVersion = 0;
  var _friendsVersion = 0;

  FriendsNotifier({
    required this.repository,
    this.searchDebounce = const Duration(milliseconds: 350),
  }) : super(FriendsState()) {
    unawaited(refresh());
  }

  void updateSearchQuery(String query) {
    _searchTimer?.cancel();
    final version = ++_searchVersion;
    final normalizedQuery = query.trim();

    if (normalizedQuery.length < 2) {
      state = state.copyWith(
        searchQuery: query,
        searchResults: const [],
        searchStatus: FriendsLoadStatus.idle,
      );
      return;
    }

    state = state.copyWith(
      searchQuery: query,
      searchResults: const [],
      searchStatus: FriendsLoadStatus.loading,
    );
    _searchTimer = Timer(
      searchDebounce,
      () => unawaited(_loadSearch(normalizedQuery, version)),
    );
  }

  Future<void> loadRequests() async {
    final version = ++_requestsVersion;
    state = state.copyWith(requestsStatus: FriendsLoadStatus.loading);

    try {
      final requests = await repository.getRequests();
      if (!mounted || version != _requestsVersion) return;
      state = state.copyWith(
        requests: requests,
        requestsStatus: FriendsLoadStatus.success,
      );
    } catch (_) {
      if (!mounted || version != _requestsVersion) return;
      state = state.copyWith(requestsStatus: FriendsLoadStatus.error);
    }
  }

  Future<void> loadFriends() async {
    final version = ++_friendsVersion;
    state = state.copyWith(friendsStatus: FriendsLoadStatus.loading);

    try {
      final friends = await repository.getFriends();
      if (!mounted || version != _friendsVersion) return;
      state = state.copyWith(
        friends: friends,
        friendsStatus: FriendsLoadStatus.success,
      );
    } catch (_) {
      if (!mounted || version != _friendsVersion) return;
      state = state.copyWith(friendsStatus: FriendsLoadStatus.error);
    }
  }

  Future<void> refresh() async {
    _searchTimer?.cancel();
    final operations = <Future<void>>[loadRequests(), loadFriends()];
    final query = state.searchQuery.trim();
    if (query.length >= 2) {
      operations.add(_loadSearch(query, ++_searchVersion));
    }
    await Future.wait(operations);
  }

  Future<FriendActionResult> sendRequest(Person person) async {
    if (person.relationship != FriendRelationship.none ||
        !_beginOperation(person.id)) {
      return FriendActionResult.ignored;
    }

    try {
      final request = await repository.sendRequest(person.id);
      if (!mounted) return FriendActionResult.ignored;
      _requestsVersion++;
      state = state.copyWith(
        searchResults: _replaceSearchPerson(request.user),
        requests: state.requests.copyWith(
          sent: [...state.requests.sent, request],
        ),
        requestsStatus: FriendsLoadStatus.success,
      );
      _refreshPendingSearch();
      return FriendActionResult.success;
    } catch (_) {
      return mounted ? FriendActionResult.failure : FriendActionResult.ignored;
    } finally {
      _endOperation(person.id);
    }
  }

  Future<FriendActionResult> acceptRequest(Person person) async {
    if (person.relationship != FriendRelationship.requestReceived ||
        person.requestId == null ||
        !_beginOperation(person.id)) {
      return FriendActionResult.ignored;
    }

    return _completeRequestAction(
      person: person,
      operation: () => repository.acceptRequest(person.requestId!),
      onSuccess: () {
        _requestsVersion++;
        _friendsVersion++;
        final accepted = person.copyWith(
          relationship: FriendRelationship.friend,
          clearRequestId: true,
        );
        state = state.copyWith(
          searchResults: _replaceSearchPerson(accepted),
          requests: state.requests.copyWith(
            received: state.requests.received
                .where((request) => request.id != person.requestId)
                .toList(growable: false),
          ),
          friends: _addFriend(accepted),
          requestsStatus: FriendsLoadStatus.success,
          friendsStatus: FriendsLoadStatus.success,
        );
        _refreshPendingSearch();
      },
    );
  }

  Future<FriendActionResult> removeRequest(Person person) async {
    if ((person.relationship != FriendRelationship.requestReceived &&
            person.relationship != FriendRelationship.requestSent) ||
        person.requestId == null ||
        !_beginOperation(person.id)) {
      return FriendActionResult.ignored;
    }

    return _completeRequestAction(
      person: person,
      operation: () => repository.removeRequest(person.requestId!),
      onSuccess: () {
        _requestsVersion++;
        final removed = person.copyWith(
          relationship: FriendRelationship.none,
          clearRequestId: true,
        );
        state = state.copyWith(
          searchResults: _replaceSearchPerson(removed),
          requests: FriendRequests(
            received: state.requests.received
                .where((request) => request.id != person.requestId)
                .toList(growable: false),
            sent: state.requests.sent
                .where((request) => request.id != person.requestId)
                .toList(growable: false),
          ),
          requestsStatus: FriendsLoadStatus.success,
        );
        _refreshPendingSearch();
      },
    );
  }

  Future<FriendActionResult> _completeRequestAction({
    required Person person,
    required Future<void> Function() operation,
    required void Function() onSuccess,
  }) async {
    try {
      await operation();
      if (!mounted) return FriendActionResult.ignored;
      onSuccess();
      return FriendActionResult.success;
    } on FriendRequestNotFoundException {
      if (!mounted) return FriendActionResult.ignored;
      await refresh();
      return mounted
          ? FriendActionResult.requestUnavailable
          : FriendActionResult.ignored;
    } catch (_) {
      return mounted ? FriendActionResult.failure : FriendActionResult.ignored;
    } finally {
      _endOperation(person.id);
    }
  }

  Future<void> _loadSearch(String query, int version) async {
    try {
      final results = await repository.search(query);
      if (!mounted || version != _searchVersion) return;
      state = state.copyWith(
        searchResults: results,
        searchStatus: FriendsLoadStatus.success,
      );
    } catch (_) {
      if (!mounted || version != _searchVersion) return;
      state = state.copyWith(searchStatus: FriendsLoadStatus.error);
    }
  }

  void _refreshPendingSearch() {
    final query = state.searchQuery.trim();
    if (state.searchStatus != FriendsLoadStatus.loading || query.length < 2) {
      return;
    }

    _searchTimer?.cancel();
    unawaited(_loadSearch(query, ++_searchVersion));
  }

  bool _beginOperation(String personId) {
    if (state.pendingPersonIds.contains(personId)) return false;
    state = state.copyWith(
      pendingPersonIds: {...state.pendingPersonIds, personId},
    );
    return true;
  }

  void _endOperation(String personId) {
    if (!mounted || !state.pendingPersonIds.contains(personId)) return;
    state = state.copyWith(
      pendingPersonIds: {
        for (final pendingId in state.pendingPersonIds)
          if (pendingId != personId) pendingId,
      },
    );
  }

  List<Person> _replaceSearchPerson(Person person) {
    return [
      for (final current in state.searchResults)
        if (current.id == person.id) person else current,
    ];
  }

  List<Person> _addFriend(Person person) {
    if (state.friends.any((friend) => friend.id == person.id)) {
      return state.friends;
    }
    return [...state.friends, person];
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
