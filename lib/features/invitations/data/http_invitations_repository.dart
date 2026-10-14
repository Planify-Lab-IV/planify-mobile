import 'package:dio/dio.dart';
import '../domain/invitations_repository.dart';
import 'invitation_exceptions.dart';

class HttpInvitationsRepository implements InvitationsRepository {
  final Dio dio;

  HttpInvitationsRepository({required this.dio});

  @override
  Future<String> resolveInvitationToken(String token) async {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      throw const InvalidInvitationException();
    }

    try {
      final response = await dio.get<dynamic>('/invitations/$trimmedToken');
      return _parseEventId(response.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 400) {
        throw const InvalidInvitationException();
      }
      if (error.response?.statusCode == 404) {
        final data = error.response?.data;
        if (data is Map && data['error'] == 'INVITATION_UNAVAILABLE') {
          throw const InvitationExpiredException();
        }
        throw const InvitationNotFoundException();
      }
      if (_isNetworkError(error)) {
        throw const NetworkInvitationException();
      }
      throw const UnknownInvitationException();
    } on InvitationException {
      rethrow;
    } catch (_) {
      throw const UnknownInvitationException();
    }
  }

  String _parseEventId(dynamic data) {
    if (data is! Map) throw const UnknownInvitationException();
    final eventId = data['eventId'];
    if (eventId is! String || eventId.trim().isEmpty) {
      throw const UnknownInvitationException();
    }
    return eventId.trim();
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
