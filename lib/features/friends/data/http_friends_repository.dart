import 'package:dio/dio.dart';

import '../domain/friend_request.dart';
import '../domain/friend_requests.dart';
import '../domain/friends_repository.dart';
import '../domain/person.dart';
import 'friends_exceptions.dart';

class HttpFriendsRepository implements FriendsRepository {
  final Dio dio;

  HttpFriendsRepository({required this.dio});

  @override
  Future<List<Person>> search(String query) async {
    return _execute(() async {
      final response = await dio.get<dynamic>(
        '/friends/search',
        queryParameters: {'q': query},
      );
      return _peopleFromResponse(response.data, 'users');
    });
  }

  @override
  Future<FriendRequest> sendRequest(String userId) async {
    return _execute(() async {
      final response = await dio.post<dynamic>(
        '/friends/requests',
        data: {'userId': userId},
      );
      final data = _mapFromResponse(response.data);
      return _requestFromResponse(
        data['request'],
        relationship: FriendRelationship.requestSent,
      );
    });
  }

  @override
  Future<FriendRequests> getRequests() async {
    return _execute(() async {
      final data = _mapFromResponse(
        (await dio.get<dynamic>('/friends/requests')).data,
      );
      return FriendRequests(
        received: _requestsFromResponse(
          data['received'],
          relationship: FriendRelationship.requestReceived,
        ),
        sent: _requestsFromResponse(
          data['sent'],
          relationship: FriendRelationship.requestSent,
        ),
      );
    });
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    await _execute(() => dio.post<void>('/friends/requests/$requestId/accept'));
  }

  @override
  Future<void> removeRequest(String requestId) async {
    await _execute(() => dio.delete<void>('/friends/requests/$requestId'));
  }

  @override
  Future<List<Person>> getFriends() async {
    return _execute(() async {
      final response = await dio.get<dynamic>('/friends');
      return _peopleFromResponse(
        response.data,
        'friends',
        relationship: FriendRelationship.friend,
      );
    });
  }

  Future<T> _execute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DioException catch (error) {
      throw _exceptionFromDio(error);
    } on FriendsException {
      rethrow;
    } catch (_) {
      throw const InvalidFriendsResponseException();
    }
  }

  FriendsException _exceptionFromDio(DioException error) {
    if (_isNetworkError(error)) return const NetworkFriendsException();

    final statusCode = error.response?.statusCode;
    final errorCode = _errorCode(error.response?.data);
    if (statusCode == 409 && errorCode == 'FRIENDSHIP_ALREADY_EXISTS') {
      return const FriendshipAlreadyExistsException();
    }
    if (statusCode == 404 && errorCode == 'FRIEND_REQUEST_NOT_FOUND') {
      return const FriendRequestNotFoundException();
    }
    return const InvalidFriendsResponseException();
  }

  String? _errorCode(dynamic data) {
    if (data is! Map) return null;
    final error = data['error'];
    return error is String ? error : null;
  }

  bool _isNetworkError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }

  List<Person> _peopleFromResponse(
    dynamic data,
    String field, {
    FriendRelationship? relationship,
  }) {
    final people = _mapFromResponse(data)[field];
    if (people is! List) throw const InvalidFriendsResponseException();

    return people
        .map(
          (person) => _personFromResponse(person, relationship: relationship),
        )
        .toList(growable: false);
  }

  List<FriendRequest> _requestsFromResponse(
    dynamic data, {
    required FriendRelationship relationship,
  }) {
    if (data is! List) throw const InvalidFriendsResponseException();

    return data
        .map(
          (request) =>
              _requestFromResponse(request, relationship: relationship),
        )
        .toList(growable: false);
  }

  FriendRequest _requestFromResponse(
    dynamic data, {
    required FriendRelationship relationship,
  }) {
    final request = _mapFromResponse(data);
    final id = _requiredString(request, 'id');
    final createdAtValue = request['createdAt'];
    final createdAt = createdAtValue is String
        ? DateTime.tryParse(createdAtValue)
        : null;
    if (createdAt == null) throw const InvalidFriendsResponseException();

    return FriendRequest(
      id: id,
      user: _personFromResponse(
        request['user'],
        relationship: relationship,
        requestId: id,
      ),
      createdAt: createdAt,
    );
  }

  Person _personFromResponse(
    dynamic data, {
    FriendRelationship? relationship,
    String? requestId,
  }) {
    final person = _mapFromResponse(data);
    final mappedRelationship =
        relationship ?? _relationshipFromResponse(person['relationship']);
    final mappedRequestId = relationship == FriendRelationship.friend
        ? null
        : requestId ?? _optionalString(person['requestId']);

    if ((mappedRelationship == FriendRelationship.requestSent ||
            mappedRelationship == FriendRelationship.requestReceived) &&
        mappedRequestId == null) {
      throw const InvalidFriendsResponseException();
    }

    return Person(
      id: _requiredString(person, 'id'),
      name: _requiredString(person, 'name'),
      username: _requiredString(person, 'username'),
      relationship: mappedRelationship,
      requestId: mappedRequestId,
    );
  }

  Map _mapFromResponse(dynamic data) {
    if (data is! Map) throw const InvalidFriendsResponseException();
    return data;
  }

  String _requiredString(Map data, String field) {
    final value = data[field];
    if (value is! String || value.trim().isEmpty) {
      throw const InvalidFriendsResponseException();
    }
    return value;
  }

  String? _optionalString(dynamic value) {
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw const InvalidFriendsResponseException();
    }
    return value;
  }

  FriendRelationship _relationshipFromResponse(dynamic value) {
    if (value is! String) throw const InvalidFriendsResponseException();

    return switch (value) {
      'request_sent' => FriendRelationship.requestSent,
      'request_received' => FriendRelationship.requestReceived,
      _ => FriendRelationship.none,
    };
  }
}
