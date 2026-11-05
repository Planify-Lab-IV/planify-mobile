import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planify/features/profile/data/avatar_picker.dart';
import 'package:planify/features/profile/data/profile_exceptions.dart';
import 'package:planify/features/profile/domain/avatar_upload.dart';

void main() {
  group('ImagePickerAvatarPicker', () {
    test(
      'conserva bytes y metadata tras la transformación del selector',
      () async {
        final gallery = _FakeGalleryImagePicker(
          XFile.fromData(
            Uint8List.fromList(_jpegBytes),
            path: 'avatar.jpg',
            name: 'avatar.jpg',
            mimeType: 'image/jpeg',
          ),
        );
        final picker = ImagePickerAvatarPicker(galleryImagePicker: gallery);

        final avatar = await picker.pickAvatar();

        expect(avatar?.bytes, orderedEquals(_jpegBytes));
        expect(avatar?.filename, 'avatar.jpg');
        expect(avatar?.mimeType, 'image/jpeg');
        expect(gallery.maxWidth, ImagePickerAvatarPicker.maxAvatarWidth);
        expect(
          gallery.imageQuality,
          ImagePickerAvatarPicker.avatarImageQuality,
        );
      },
    );

    test(
      'acepta una extensión admitida si la plataforma no informa MIME',
      () async {
        final picker = ImagePickerAvatarPicker(
          galleryImagePicker: _FakeGalleryImagePicker(
            XFile.fromData(
              Uint8List.fromList(_webpBytes),
              path: 'avatar.webp',
              name: 'avatar.webp',
            ),
          ),
        );

        expect((await picker.pickAvatar())?.mimeType, 'image/webp');
      },
    );

    test('devuelve null cuando la persona cancela la selección', () async {
      final picker = ImagePickerAvatarPicker(
        galleryImagePicker: _FakeGalleryImagePicker(null),
      );

      expect(await picker.pickAvatar(), isNull);
    });

    test(
      'rechaza formatos no admitidos y archivos que superan 2 MiB',
      () async {
        final invalidFormat = ImagePickerAvatarPicker(
          galleryImagePicker: _FakeGalleryImagePicker(
            XFile.fromData(
              Uint8List.fromList([0x47, 0x49, 0x46, 0x38]),
              path: 'avatar.gif',
              name: 'avatar.gif',
              mimeType: 'image/gif',
            ),
          ),
        );
        final tooLarge = ImagePickerAvatarPicker(
          galleryImagePicker: _FakeGalleryImagePicker(
            XFile.fromData(
              Uint8List(AvatarUpload.maxBytes + 1),
              path: 'avatar.png',
              name: 'avatar.png',
              mimeType: 'image/png',
            ),
          ),
        );

        expect(
          invalidFormat.pickAvatar(),
          throwsA(
            isA<InvalidAvatarFileException>().having(
              (error) => error.reason,
              'reason',
              AvatarUploadValidationError.unsupportedFormat,
            ),
          ),
        );
        expect(
          tooLarge.pickAvatar(),
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

    test('detecta JPEG aunque el nombre conserve la extensión HEIC', () async {
      final picker = ImagePickerAvatarPicker(
        galleryImagePicker: _FakeGalleryImagePicker(
          XFile.fromData(
            Uint8List.fromList(_jpegBytes),
            path: 'avatar.heic',
            name: 'avatar.heic',
          ),
        ),
      );

      final avatar = await picker.pickAvatar();

      expect(avatar?.mimeType, 'image/jpeg');
      expect(avatar?.filename, 'avatar.jpg');
    });

    test(
      'no confía en application/octet-stream si los bytes son JPEG',
      () async {
        final picker = ImagePickerAvatarPicker(
          galleryImagePicker: _FakeGalleryImagePicker(
            XFile.fromData(
              Uint8List.fromList(_jpegBytes),
              path: 'avatar.jpg',
              name: 'avatar.jpg',
              mimeType: 'application/octet-stream',
            ),
          ),
        );

        expect((await picker.pickAvatar())?.mimeType, 'image/jpeg');
      },
    );
  });
}

const _jpegBytes = [0xff, 0xd8, 0xff, 0xe0];
const _webpBytes = [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50];

class _FakeGalleryImagePicker implements GalleryImagePicker {
  final XFile? result;
  double? maxWidth;
  int? imageQuality;

  _FakeGalleryImagePicker(this.result);

  @override
  Future<XFile?> pickImage({
    required double maxWidth,
    required int imageQuality,
  }) async {
    this.maxWidth = maxWidth;
    this.imageQuality = imageQuality;
    return result;
  }
}
