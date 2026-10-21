import '../domain/friend_request.dart';
import '../domain/friend_requests.dart';
import '../domain/friends_repository.dart';
import '../domain/person.dart';
import 'friends_exceptions.dart';

// Simula el estado remoto de amistades para desarrollar la pantalla sin HTTP.
class FakeFriendsRepository implements FriendsRepository {
  final Duration delay;
  bool shouldThrowError;

  final Map<String, Person> _peopleById = {};
  final Map<String, FriendRequest> _receivedRequestsById = {};
  final Map<String, FriendRequest> _sentRequestsById = {};
  final Set<String> _friendIds = {};
  final Set<String> _unavailableRequestIds = {};
  var _requestSequence = 0;

  FakeFriendsRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
    List<Person>? searchablePeople,
    List<FriendRequest>? initialReceivedRequests,
    List<FriendRequest>? initialSentRequests,
    List<Person>? initialFriends,
  }) {
    for (final person in searchablePeople ?? _defaultSearchablePeople) {
      _storePerson(person);
    }
    for (final request in initialReceivedRequests ?? _defaultReceivedRequests) {
      _seedRequest(request, received: true);
    }
    for (final request in initialSentRequests ?? _defaultSentRequests) {
      _seedRequest(request, received: false);
    }
    for (final person in initialFriends ?? _defaultFriends) {
      _storePerson(person);
      if (_relationshipFor(person.id) != FriendRelationship.none) {
        throw ArgumentError.value(
          person.id,
          'initialFriends',
          'A person cannot be a friend and have a pending request.',
        );
      }
      _friendIds.add(person.id);
    }
  }

  // Simula que la otra persona canceló o aceptó la solicitud fuera de la app.
  void markRequestUnavailable(String requestId) {
    _unavailableRequestIds.add(requestId);
  }

  @override
  Future<List<Person>> search(String query) async {
    await _waitOrThrow();
    final normalizedQuery = query.trim().toLowerCase();
    return List.unmodifiable([
      for (final person in _peopleById.values)
        if (person.username.toLowerCase().contains(normalizedQuery))
          _personWithRelationship(person.id),
    ]);
  }

  @override
  Future<FriendRequest> sendRequest(String userId) async {
    await _waitOrThrow();
    if (_relationshipFor(userId) != FriendRelationship.none) {
      throw const FriendsOperationException();
    }

    final person = _peopleById[userId];
    if (person == null) throw const FriendsOperationException();

    final request = FriendRequest(
      id: _nextRequestId(),
      user: person,
      createdAt: DateTime.now(),
    );
    _sentRequestsById[request.id] = request;
    return _requestWithRelationship(request, FriendRelationship.requestSent);
  }

  @override
  Future<FriendRequests> getRequests() async {
    await _waitOrThrow();
    return FriendRequests(
      received: _receivedRequestsById.values
          .map(
            (request) => _requestWithRelationship(
              request,
              FriendRelationship.requestReceived,
            ),
          )
          .toList(growable: false),
      sent: _sentRequestsById.values
          .map(
            (request) => _requestWithRelationship(
              request,
              FriendRelationship.requestSent,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    await _waitOrThrow();
    _throwIfRequestUnavailable(requestId);
    final request = _receivedRequestsById.remove(requestId);
    if (request == null) throw const FriendRequestNotFoundException();

    _friendIds.add(request.user.id);
  }

  @override
  Future<void> removeRequest(String requestId) async {
    await _waitOrThrow();
    _throwIfRequestUnavailable(requestId);
    final removed =
        _receivedRequestsById.remove(requestId) ??
        _sentRequestsById.remove(requestId);
    if (removed == null) throw const FriendRequestNotFoundException();
  }

  @override
  Future<List<Person>> getFriends() async {
    await _waitOrThrow();
    return List.unmodifiable(
      _friendIds.map(_personWithRelationship).toList(growable: false),
    );
  }

  Future<void> _waitOrThrow() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldThrowError) throw const FriendsOperationException();
  }

  void _storePerson(Person person) {
    _peopleById[person.id] = person.copyWith(
      relationship: FriendRelationship.none,
      clearRequestId: true,
    );
  }

  void _seedRequest(FriendRequest request, {required bool received}) {
    _storePerson(request.user);
    if (_relationshipFor(request.user.id) != FriendRelationship.none) {
      throw ArgumentError.value(
        request.user.id,
        'initial requests',
        'A person cannot have more than one relationship.',
      );
    }
    final requests = received ? _receivedRequestsById : _sentRequestsById;
    if (requests.containsKey(request.id)) {
      throw ArgumentError.value(
        request.id,
        'initial requests',
        'A request identifier must be unique.',
      );
    }
    requests[request.id] = FriendRequest(
      id: request.id,
      user: _peopleById[request.user.id]!,
      createdAt: request.createdAt,
    );
  }

  FriendRelationship _relationshipFor(String userId) {
    if (_friendIds.contains(userId)) return FriendRelationship.friend;
    if (_sentRequestsById.values.any((request) => request.user.id == userId)) {
      return FriendRelationship.requestSent;
    }
    if (_receivedRequestsById.values.any(
      (request) => request.user.id == userId,
    )) {
      return FriendRelationship.requestReceived;
    }
    return FriendRelationship.none;
  }

  Person _personWithRelationship(String userId) {
    final person = _peopleById[userId];
    if (person == null) throw const FriendsOperationException();
    final requestId = _requestIdForUser(userId);
    return person.copyWith(
      relationship: _relationshipFor(userId),
      requestId: requestId,
      clearRequestId: requestId == null,
    );
  }

  String? _requestIdForUser(String userId) {
    for (final request in _sentRequestsById.values) {
      if (request.user.id == userId) return request.id;
    }
    for (final request in _receivedRequestsById.values) {
      if (request.user.id == userId) return request.id;
    }
    return null;
  }

  FriendRequest _requestWithRelationship(
    FriendRequest request,
    FriendRelationship relationship,
  ) {
    return request.copyWith(
      user: _personWithRelationship(
        request.user.id,
      ).copyWith(relationship: relationship, requestId: request.id),
    );
  }

  void _throwIfRequestUnavailable(String requestId) {
    if (!_unavailableRequestIds.remove(requestId)) return;
    _receivedRequestsById.remove(requestId);
    _sentRequestsById.remove(requestId);
    throw const FriendRequestNotFoundException();
  }

  String _nextRequestId() {
    String requestId;
    do {
      _requestSequence++;
      requestId = 'request-$_requestSequence';
    } while (_receivedRequestsById.containsKey(requestId) ||
        _sentRequestsById.containsKey(requestId));
    return requestId;
  }

  static const List<Person> _defaultSearchablePeople = [
    Person(
      id: 'friend-ana',
      name: 'Ana Pérez',
      username: 'ana',
      relationship: FriendRelationship.none,
    ),
    Person(
      id: 'friend-bruno',
      name: 'Bruno Díaz',
      username: 'bruno',
      relationship: FriendRelationship.none,
    ),
    Person(
      id: 'friend-carla',
      name: 'Carla Gómez',
      username: 'carla',
      relationship: FriendRelationship.none,
    ),
    Person(
      id: 'friend-diego',
      name: 'Diego Ruiz',
      username: 'diego',
      relationship: FriendRelationship.none,
    ),
  ];

  static final List<FriendRequest> _defaultReceivedRequests = [
    FriendRequest(
      id: 'request-ana',
      user: _defaultSearchablePeople[0],
      createdAt: DateTime(2026, 10, 20),
    ),
  ];

  static final List<FriendRequest> _defaultSentRequests = [
    FriendRequest(
      id: 'request-bruno',
      user: _defaultSearchablePeople[1],
      createdAt: DateTime(2026, 10, 19),
    ),
  ];

  static final List<Person> _defaultFriends = [_defaultSearchablePeople[2]];
}
