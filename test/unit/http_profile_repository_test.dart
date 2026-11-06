import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/profile/data/http_profile_repository.dart';
import 'package:planify/features/profile/data/profile_exceptions.dart';
import 'package:planify/features/profile/domain/avatar_upload.dart';

class _InspectingAdapter implements HttpClientAdapter {
  _InspectingAdapter({required this.body, this.inspect});

  final dynamic body;
  final void Function(RequestOptions options)? inspect;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    inspect?.call(options);
    if (requestStream != null) await requestStream.drain<void>();
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  const user = {
    'id': 'user-1',
    'name': 'Dev One',
    'username': 'dev1',
    'email': 'dev1@planify.dev',
  };

  AvatarUpload avatar(String extension) {
    final mimeType = switch (extension) {
      'jpg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/gif',
    };
    return AvatarUpload(
      bytes: Uint8List.fromList(switch (extension) {
        'jpg' => [0xff, 0xd8, 0xff],
        'png' => [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
        'webp' => [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50],
        _ => [0x47, 0x49, 0x46],
      }),
      filename: 'avatar.$extension',
      mimeType: mimeType,
    );
  }

  Dio resolving(
    dynamic body, {
    void Function(RequestOptions options)? inspect,
    String baseUrl = 'http://localhost:3000',
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    dio.httpClientAdapter = _InspectingAdapter(body: body, inspect: inspect);
    return dio;
  }

  Dio rejecting({
    required DioExceptionType type,
    int? statusCode,
    dynamic body,
  }) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: type,
            response: statusCode == null
                ? null
                : Response<dynamic>(
                    requestOptions: options,
                    statusCode: statusCode,
                    data: body,
                  ),
          ),
        ),
      ),
    );
    return dio;
  }

  group('HttpProfileRepository', () {
    test(
      'gets the authenticated profile and resolves a relative avatar URL',
      () async {
        RequestOptions? request;
        final repository = HttpProfileRepository(
          dio: resolving({
            'user': {...user, 'avatarUrl': '/uploads/avatars/dev1.jpg'},
          }, inspect: (options) => request = options),
        );

        final profile = await repository.getMyProfile();

        expect(request?.method, 'GET');
        expect(request?.path, '/auth/me');
        expect(
          profile.avatarUrl,
          'http://localhost:3000/uploads/avatars/dev1.jpg',
        );
      },
    );

    test(
      'keeps null and absolute HTTPS avatar URLs from the profile response',
      () async {
        final noAvatar = await HttpProfileRepository(
          dio: resolving({
            'user': {...user, 'avatarUrl': null},
          }),
        ).getMyProfile();
        final s3Avatar = await HttpProfileRepository(
          dio: resolving({
            'user': {
              ...user,
              'avatarUrl': 'https://bucket.s3.test/avatars/dev1.jpg',
            },
          }),
        ).getMyProfile();

        expect(noAvatar.avatarUrl, isNull);
        expect(s3Avatar.avatarUrl, 'https://bucket.s3.test/avatars/dev1.jpg');
      },
    );

    test('sends only the requested name in multipart form data', () async {
      RequestOptions? request;
      final repository = HttpProfileRepository(
        dio: resolving({'user': user}, inspect: (options) => request = options),
      );

      await repository.updateProfile(name: 'Dev One Updated');

      final form = request!.data as FormData;
      expect(request!.method, 'PATCH');
      expect(request!.path, '/me/profile');
      expect(Map.fromEntries(form.fields), {'name': 'Dev One Updated'});
      expect(form.files, isEmpty);
      expect(request!.contentType, startsWith('multipart/form-data'));
    });

    test(
      'sends bytes, filename and MIME for supported avatar formats',
      () async {
        for (final extension in ['jpg', 'png', 'webp']) {
          RequestOptions? request;
          final repository = HttpProfileRepository(
            dio: resolving({
              'user': user,
            }, inspect: (options) => request = options),
          );

          await repository.updateProfile(
            name: 'Dev One Updated',
            avatar: avatar(extension),
          );

          final form = request!.data as FormData;
          final file = form.files.single;
          expect(Map.fromEntries(form.fields), {'name': 'Dev One Updated'});
          expect(file.key, 'avatar');
          expect(file.value.filename, 'avatar.$extension');
          expect(file.value.length, greaterThan(0));
          expect(
            file.value.contentType.toString(),
            extension == 'jpg' ? 'image/jpeg' : 'image/$extension',
          );
        }
      },
    );

    test(
      'rejects invalid avatar format and size before sending a request',
      () async {
        final repository = HttpProfileRepository(
          dio: resolving({'user': user}),
        );

        expect(
          repository.updateProfile(avatar: avatar('gif')),
          throwsA(
            isA<InvalidAvatarFileException>().having(
              (error) => error.reason,
              'reason',
              AvatarUploadValidationError.unsupportedFormat,
            ),
          ),
        );
        expect(
          repository.updateProfile(
            avatar: AvatarUpload(
              bytes: Uint8List.fromList([0x47, 0x49, 0x46, 0x38]),
              filename: 'avatar.jpg',
              mimeType: 'image/jpeg',
            ),
          ),
          throwsA(
            isA<InvalidAvatarFileException>().having(
              (error) => error.reason,
              'reason',
              AvatarUploadValidationError.unsupportedFormat,
            ),
          ),
        );
        expect(
          repository.updateProfile(
            avatar: AvatarUpload(
              bytes: Uint8List(AvatarUpload.maxBytes + 1),
              filename: 'avatar.png',
              mimeType: 'image/png',
            ),
          ),
          throwsA(
            isA<InvalidAvatarFileException>().having(
              (error) => error.reason,
              'reason',
              AvatarUploadValidationError.tooLarge,
            ),
          ),
        );
      },
    );

    test('maps HTTP storage and network errors', () async {
      expect(
        HttpProfileRepository(
          dio: rejecting(type: DioExceptionType.badResponse, statusCode: 400),
        ).updateProfile(name: 'too long'),
        throwsA(isA<InvalidProfileDataException>()),
      );
      expect(
        HttpProfileRepository(
          dio: rejecting(
            type: DioExceptionType.badResponse,
            statusCode: 503,
            body: {'error': 'AVATAR_STORAGE_UNAVAILABLE'},
          ),
        ).updateProfile(name: 'Dev One'),
        throwsA(isA<AvatarStorageUnavailableException>()),
      );
      expect(
        HttpProfileRepository(
          dio: rejecting(type: DioExceptionType.connectionError),
        ).getMyProfile,
        throwsA(isA<NetworkProfileException>()),
      );
    });
  });
}
