import 'package:dio/dio.dart';

import '../domain/availability_heatmap_dto.dart';
import '../domain/availability_repository.dart';
import '../domain/slot.dart';
import 'availability_exceptions.dart';

class HttpAvailabilityRepository implements AvailabilityRepository {
  final Dio dio;

  HttpAvailabilityRepository({required this.dio});

  @override
  Future<List<Slot>> load(String eventId) async {
    final normalizedEventId = _normalizedEventId(eventId);

    try {
      final response = await dio.get<dynamic>(
        '/events/$normalizedEventId/availability',
      );
      return _slotsFromResponse(response.data);
    } on DioException catch (error) {
      if (_isNetworkError(error)) {
        throw const NetworkAvailabilityException();
      }
      throw const InvalidAvailabilityResponseException();
    } on AvailabilityException {
      rethrow;
    } catch (_) {
      throw const InvalidAvailabilityResponseException();
    }
  }

  @override
  Future<void> save(String eventId, List<Slot> slots) async {
    final normalizedEventId = _normalizedEventId(eventId);

    try {
      await dio.put<dynamic>(
        '/events/$normalizedEventId/availability',
        data: {
          'slots': slots
              .map(
                (slot) => {
                  'weekDay': slot.weekDay,
                  'hourBlock': slot.hourBlock,
                },
              )
              .toList(growable: false),
        },
      );
    } on DioException catch (error) {
      if (_isNetworkError(error)) {
        throw const NetworkAvailabilityException();
      }
      throw const AvailabilitySaveException();
    } on AvailabilityException {
      rethrow;
    } catch (_) {
      throw const AvailabilitySaveException();
    }
  }

  @override
  Future<AvailabilityHeatmapDto> heatmap(String eventId) {
    throw UnsupportedError('Availability heatmap is not integrated yet');
  }

  String _normalizedEventId(String eventId) {
    final normalizedEventId = eventId.trim();
    if (normalizedEventId.isEmpty) {
      throw const InvalidAvailabilityResponseException();
    }
    return normalizedEventId;
  }

  List<Slot> _slotsFromResponse(dynamic data) {
    if (data is! Map || data['slots'] is! List) {
      throw const InvalidAvailabilityResponseException();
    }

    return (data['slots'] as List<dynamic>)
        .map((slot) {
          if (slot is! Map ||
              slot['weekDay'] is! int ||
              slot['hourBlock'] is! int) {
            throw const InvalidAvailabilityResponseException();
          }
          return Slot(
            weekDay: slot['weekDay'] as int,
            hourBlock: slot['hourBlock'] as int,
          );
        })
        .toList(growable: false);
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
}
