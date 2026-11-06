import 'package:dio/dio.dart';

import '../domain/avatar_upload.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';
import 'avatar_url_resolver.dart';
import 'profile_exceptions.dart';

class HttpProfileRepository implements ProfileRepository {
  final Dio dio;

  HttpProfileRepository({required this.dio});

  @override
  Future<UserProfile> getMyProfile() async {
    try {
      final response = await dio.get<dynamic>('/auth/me');
      return _profileFromResponse(response.data);
    } on DioException catch (error) {
      throw _exceptionFromDio(error);
    } on ProfileException {
      rethrow;
    } catch (_) {
      throw const InvalidProfileResponseException();
    }
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    AvatarUpload? avatar,
  }) async {
    try {
      final formData = FormData();
      if (name != null) formData.fields.add(MapEntry('name', name));
      if (avatar != null) {
        _throwIfInvalidAvatar(avatar);
        formData.files.add(
          MapEntry(
            'avatar',
            MultipartFile.fromBytes(
              avatar.bytes,
              filename: avatar.filename,
              contentType: _avatarContentType(avatar.mimeType),
            ),
          ),
        );
      }

      final response = await dio.patch<dynamic>('/me/profile', data: formData);
      return _profileFromResponse(response.data);
    } on DioException catch (error) {
      throw _exceptionFromDio(error);
    } on ProfileException {
      rethrow;
    } catch (_) {
      throw const InvalidProfileResponseException();
    }
  }

  UserProfile _profileFromResponse(dynamic data) {
    if (data is! Map) throw const InvalidProfileResponseException();

    final user = data['user'];
    if (user is! Map) throw const InvalidProfileResponseException();

    final id = user['id'];
    final name = user['name'];
    final username = user['username'];
    final email = user['email'];
    final avatarUrl = user['avatarUrl'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.isEmpty ||
        username is! String ||
        username.isEmpty ||
        email is! String ||
        email.isEmpty ||
        (avatarUrl != null && avatarUrl is! String)) {
      throw const InvalidProfileResponseException();
    }

    return UserProfile(
      name: name,
      username: username,
      email: email,
      avatarUrl: resolveAvatarUrl(avatarUrl, dio.options.baseUrl),
    );
  }

  void _throwIfInvalidAvatar(AvatarUpload avatar) {
    final validationError = avatar.validationError;
    if (validationError != null) {
      throw InvalidAvatarFileException(validationError);
    }
  }

  DioMediaType _avatarContentType(String mimeType) {
    return switch (mimeType) {
      'image/jpeg' => DioMediaType('image', 'jpeg'),
      'image/png' => DioMediaType('image', 'png'),
      'image/webp' => DioMediaType('image', 'webp'),
      _ => throw const InvalidAvatarFileException(
        AvatarUploadValidationError.unsupportedFormat,
      ),
    };
  }

  ProfileException _exceptionFromDio(DioException error) {
    if (_isNetworkError(error)) return const NetworkProfileException();

    final statusCode = error.response?.statusCode;
    if (statusCode == 400) return const InvalidProfileDataException();
    if (statusCode == 503 &&
        error.response?.data is Map &&
        (error.response!.data as Map)['error'] ==
            'AVATAR_STORAGE_UNAVAILABLE') {
      return const AvatarStorageUnavailableException();
    }
    return const InvalidProfileResponseException();
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
