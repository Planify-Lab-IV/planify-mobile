import 'dart:typed_data';

enum AvatarUploadValidationError { unsupportedFormat, tooLarge }

/// Archivo de avatar listo para previsualizar y enviar a la API.
///
/// No representa una ruta local: los navegadores no permiten que una ruta de
/// archivo sea utilizada posteriormente para leer o subir el contenido.
class AvatarUpload {
  static const maxBytes = 2 * 1024 * 1024;

  static const _supportedMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};

  final Uint8List bytes;
  final String filename;
  final String mimeType;

  const AvatarUpload({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  AvatarUploadValidationError? get validationError {
    if (bytes.lengthInBytes > maxBytes) {
      return AvatarUploadValidationError.tooLarge;
    }
    if (filename.trim().isEmpty || !_supportedMimeTypes.contains(mimeType)) {
      return AvatarUploadValidationError.unsupportedFormat;
    }
    return null;
  }

  /// Normaliza el MIME que informa el selector. Cuando una plataforma no lo
  /// proporciona, se usa exclusivamente una extensión admitida como respaldo.
  static String? resolveMimeType({
    required String filename,
    String? reportedMimeType,
  }) {
    final reported = reportedMimeType?.split(';').first.trim().toLowerCase();
    switch (reported) {
      case 'image/jpeg' || 'image/jpg':
        return 'image/jpeg';
      case 'image/png':
        return 'image/png';
      case 'image/webp':
        return 'image/webp';
      case null || '':
        return switch (filename.split('.').last.toLowerCase()) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => null,
        };
      default:
        return null;
    }
  }
}
