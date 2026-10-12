import 'package:image_picker/image_picker.dart';

// Abstracción del selector de avatar para mantener los plugins nativos fuera
// de la pantalla y poder sustituirlos por un fake en los tests.
abstract interface class AvatarPicker {
  Future<String?> pickAvatar();
}

// Puerto reducido de [ImagePicker] que permite probar la configuración de
// selección sin abrir una pantalla nativa.
abstract interface class GalleryImagePicker {
  Future<String?> pickImage({
    required double maxWidth,
    required int imageQuality,
  });
}

class ImagePickerAvatarPicker implements AvatarPicker {
  static const maxAvatarWidth = 1280.0;
  static const avatarImageQuality = 80;

  final GalleryImagePicker _galleryImagePicker;

  ImagePickerAvatarPicker({GalleryImagePicker? galleryImagePicker})
    : _galleryImagePicker = galleryImagePicker ?? _ImagePickerGallery();

  @override
  Future<String?> pickAvatar() {
    return _galleryImagePicker.pickImage(
      maxWidth: maxAvatarWidth,
      imageQuality: avatarImageQuality,
    );
  }
}

class _ImagePickerGallery implements GalleryImagePicker {
  final ImagePicker _imagePicker;

  _ImagePickerGallery({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  @override
  Future<String?> pickImage({
    required double maxWidth,
    required int imageQuality,
  }) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      imageQuality: imageQuality,
    );
    return image?.path;
  }
}
