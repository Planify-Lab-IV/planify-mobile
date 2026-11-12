import 'package:image_picker/image_picker.dart';

import '../domain/avatar_upload.dart';
import 'profile_exceptions.dart';

// Abstracción del selector de avatar para mantener los plugins nativos fuera
// de la pantalla y poder sustituirlos por un fake en los tests.
abstract interface class AvatarPicker {
  Future<AvatarUpload?> pickAvatar();
}

// Puerto reducido de [ImagePicker] que permite probar la configuración de
// selección sin abrir una pantalla nativa.
abstract interface class GalleryImagePicker {
  Future<XFile?> pickImage({
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
  Future<AvatarUpload?> pickAvatar() async {
    // image_picker para iOS recodifica imágenes HEIC/HEIF a JPEG cuando se
    // solicita una transformación (ancho o calidad). Ambos parámetros se
    // mantienen para que el archivo llegue en un formato admitido por la API.
    final image = await _galleryImagePicker.pickImage(
      maxWidth: maxAvatarWidth,
      imageQuality: avatarImageQuality,
    );
    if (image == null) return null;

    final length = await image.length();
    if (length > AvatarUpload.maxBytes) {
      throw const InvalidAvatarFileException(
        AvatarUploadValidationError.tooLarge,
      );
    }

    final bytes = await image.readAsBytes();
    final mimeType =
        AvatarUpload.detectMimeType(bytes) ??
        AvatarUpload.resolveMimeType(
          filename: image.name,
          reportedMimeType: image.mimeType,
        ) ??
        '';

    final avatar = AvatarUpload(
      bytes: bytes,
      filename: AvatarUpload.filenameForMimeType(
        filename: image.name,
        mimeType: mimeType,
      ),
      mimeType: mimeType,
    );
    final validationError = avatar.validationError;
    if (validationError != null) {
      throw InvalidAvatarFileException(validationError);
    }
    return avatar;
  }
}

class _ImagePickerGallery implements GalleryImagePicker {
  final ImagePicker _imagePicker;

  _ImagePickerGallery({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  @override
  Future<XFile?> pickImage({
    required double maxWidth,
    required int imageQuality,
  }) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      imageQuality: imageQuality,
    );
    return image;
  }
}
