import 'package:dio/dio.dart';

import '../domain/attendance_status.dart';
import '../domain/event.dart';
import '../domain/event_draft.dart';
import '../domain/event_participant.dart';
import '../domain/event_status.dart';
import '../domain/events_repository.dart';
import 'event_exceptions.dart';

class HttpEventsRepository implements EventsRepository {
  final Dio dio;

  HttpEventsRepository({required this.dio});

  @override
  Future<Event> createEvent(EventDraft draft) async {
    try {
      final response = await dio.post<dynamic>(
        '/events',
        data: _createEventRequest(draft),
      );
      return _eventFromResponse(response.data);
    } on DioException catch (error) {
      if (_isNetworkError(error)) {
        throw const NetworkEventException();
      }
      throw const InvalidEventResponseException();
    } on EventsException {
      rethrow;
    } catch (_) {
      throw const InvalidEventResponseException();
    }
  }

  Map<String, Object> _createEventRequest(EventDraft draft) {
    final request = <String, Object>{
      'name': draft.name,
      'location': draft.location,
    };

    if (draft.isNewGroup) {
      if (draft.newGroupName != null) {
        request['newGroupName'] = draft.newGroupName!;
      }
      request['memberIdentifiers'] = draft.newGroupMembers;
    } else if (draft.selectedGroupId != null) {
      request['groupId'] = draft.selectedGroupId!;
    }

    return request;
  }

  Event _eventFromResponse(dynamic data) {
    if (data is! Map) throw const InvalidEventResponseException();

    return Event(
      id: _requiredString(data, 'id'),
      name: _requiredString(data, 'name'),
      location: _requiredString(data, 'location'),
      organizerId: _requiredString(data, 'organizerId'),
      groupId: _requiredString(data, 'groupId'),
      status:  _eventStatus(data['status']),
      createdAt: _requiredDateTime(data, 'createdAt'),
      updatedAt: _requiredDateTime(data, 'updatedAt'),
      participants: _participantsFromResponse(data['participants']),
    );
  }

  List<EventParticipant> _participantsFromResponse(dynamic data) {
    if (data is! List) throw const InvalidEventResponseException();

    return data.map(_participantFromResponse).toList(growable: false);
  }

  EventParticipant _participantFromResponse(dynamic data) {
    if (data is! Map) throw const InvalidEventResponseException();

    final userId = data['userId'];
    final isAnonymous = data['isAnonymous'];
    final isOrganizer = data['isOrganizer'];
    if ((userId != null && userId is! String) ||
        isAnonymous is! bool ||
        isOrganizer is! bool) {
      throw const InvalidEventResponseException();
    }

    return EventParticipant(
      eventId: _requiredString(data, 'eventId'),
      userId: userId as String?,
      username: _requiredString(data, 'username'),
      isAnonymous: isAnonymous,
      isOrganizer: isOrganizer,
    );
  }

  String _requiredString(Map<dynamic, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw const InvalidEventResponseException();
    }
    return value;
  }

  DateTime _requiredDateTime(Map<dynamic, dynamic> data, String key) {
    final value = data[key];
    if (value is! String) throw const InvalidEventResponseException();

    final dateTime = DateTime.tryParse(value);
    if (dateTime == null) throw const InvalidEventResponseException();
    return dateTime;
  }

  EventStatus _eventStatus(dynamic value) {
    return switch (value) {
      'active' => EventStatus.active,
      'cancelled' => EventStatus.cancelled,
      _ => throw const InvalidEventResponseException(),
    };
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

  @override
  Future<Event?> getEvent(String eventId) {
    throw const UnsupportedEventOperationException();
  }

  @override
  Future<void> cancel(String eventId) {
    throw const UnsupportedEventOperationException();
  }

  @override
  Future<AttendanceStatus> getCurrentUserAttendance(String eventId) {
    throw const UnsupportedEventOperationException();
  }

  @override
  Future<void> updateCurrentUserAttendance(
    String eventId,
    AttendanceResponse response,
  ) {
    throw const UnsupportedEventOperationException();
  }
}
