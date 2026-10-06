import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/profile/data/avatar_picker.dart';

void main() {
  group('ImagePickerAvatarPicker', () {
    test('devuelve la ruta elegida y solicita una imagen reducida', () async {
      final gallery = _FakeGalleryImagePicker('/tmp/avatar.jpg');
      final picker = ImagePickerAvatarPicker(galleryImagePicker: gallery);

      final path = await picker.pickAvatar();

      expect(path, '/tmp/avatar.jpg');
      expect(gallery.maxWidth, ImagePickerAvatarPicker.maxAvatarWidth);
      expect(gallery.imageQuality, ImagePickerAvatarPicker.avatarImageQuality);
    });

    test('devuelve null cuando la persona cancela la selección', () async {
      final picker = ImagePickerAvatarPicker(
        galleryImagePicker: _FakeGalleryImagePicker(null),
      );

      expect(await picker.pickAvatar(), isNull);
    });
  });
}

class _FakeGalleryImagePicker implements GalleryImagePicker {
  final String? result;
  double? maxWidth;
  int? imageQuality;

  _FakeGalleryImagePicker(this.result);

  @override
  Future<String?> pickImage({
    required double maxWidth,
    required int imageQuality,
  }) async {
    this.maxWidth = maxWidth;
    this.imageQuality = imageQuality;
    return result;
  }
}
