import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/profile/data/http_profile_repository.dart';
import 'package:planify/features/profile/data/profile_exceptions.dart';

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
    if (requestStream != null) {
      await requestStream.drain<void>();
    }
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

  Future<String> avatarFile(String extension) async {
    final directory = await Directory.systemTemp.createTemp('planify-avatar-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File(
      '${directory.path}${Platform.pathSeparator}avatar.$extension',
    );
    await file.writeAsBytes([0, 1, 2]);
    return file.path;
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
        expect(profile.name, 'Dev One');
        expect(
          profile.avatarUrl,
          'http://localhost:3000/uploads/avatars/dev1.jpg',
        );
      },
    );

    test(
      'keeps a null or absolute avatar URL from the profile response',
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
              'avatarUrl':
                  'https://bucket.s3.us-east-1.amazonaws.com/avatars/dev1.jpg',
            },
          }),
        ).getMyProfile();

        expect(noAvatar.avatarUrl, isNull);
        expect(
          s3Avatar.avatarUrl,
          'https://bucket.s3.us-east-1.amazonaws.com/avatars/dev1.jpg',
        );
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

    test('sends an image with an explicit JPEG MIME type', () async {
      RequestOptions? request;
      final repository = HttpProfileRepository(
        dio: resolving({'user': user}, inspect: (options) => request = options),
      );

      await repository.updateProfile(avatarFilePath: await avatarFile('jpg'));

      final form = request!.data as FormData;
      expect(form.fields, isEmpty);
      expect(form.files, hasLength(1));
      expect(form.files.single.key, 'avatar');
      expect(form.files.single.value.contentType.toString(), 'image/jpeg');
      expect(request!.contentType, startsWith('multipart/form-data'));
    });

    test('sends name and supported PNG or WebP avatars together', () async {
      for (final extension in ['png', 'webp']) {
        RequestOptions? request;
        final repository = HttpProfileRepository(
          dio: resolving({
            'user': user,
          }, inspect: (options) => request = options),
        );

        await repository.updateProfile(
          name: 'Dev One Updated',
          avatarFilePath: await avatarFile(extension),
        );

        final form = request!.data as FormData;
        expect(Map.fromEntries(form.fields), {'name': 'Dev One Updated'});
        expect(
          form.files.single.value.contentType.toString(),
          'image/$extension',
        );
      }
    });

    test('maps 400 invalid data and 503 unavailable storage errors', () async {
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
    });

    test(
      'maps malformed data, unsupported uploads, and network errors',
      () async {
        expect(
          HttpProfileRepository(
            dio: resolving({
              'user': {'name': 'Dev One'},
            }),
          ).getMyProfile,
          throwsA(isA<InvalidProfileResponseException>()),
        );
        expect(
          HttpProfileRepository(
            dio: resolving({'user': user}),
          ).updateProfile(avatarFilePath: await avatarFile('heic')),
          throwsA(isA<InvalidProfileDataException>()),
        );
        expect(
          HttpProfileRepository(
            dio: rejecting(type: DioExceptionType.connectionError),
          ).getMyProfile,
          throwsA(isA<NetworkProfileException>()),
        );
      },
    );
  });
}
