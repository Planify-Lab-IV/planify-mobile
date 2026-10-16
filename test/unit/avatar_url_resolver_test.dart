import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/profile/data/avatar_url_resolver.dart';

void main() {
  group('resolveAvatarUrl', () {
    test('returns null when the backend has no avatar', () {
      expect(resolveAvatarUrl(null, 'http://localhost:3000'), isNull);
    });

    test('resolves a relative local-storage URL', () {
      expect(
        resolveAvatarUrl('/uploads/avatars/dev1.jpg', 'http://localhost:3000'),
        'http://localhost:3000/uploads/avatars/dev1.jpg',
      );
    });

    test('normalizes the base URL and a relative path without slashes', () {
      expect(
        resolveAvatarUrl('uploads/avatars/dev1.jpg', 'http://localhost:3000/'),
        'http://localhost:3000/uploads/avatars/dev1.jpg',
      );
    });

    test('keeps absolute HTTP and HTTPS URLs', () {
      expect(
        resolveAvatarUrl(
          'http://cdn.planify.test/avatar.jpg',
          'http://api.test',
        ),
        'http://cdn.planify.test/avatar.jpg',
      );
      expect(
        resolveAvatarUrl(
          'https://bucket.s3.test/avatar.jpg',
          'http://api.test',
        ),
        'https://bucket.s3.test/avatar.jpg',
      );
    });
  });
}
