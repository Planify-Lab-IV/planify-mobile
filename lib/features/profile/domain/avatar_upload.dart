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
    final detectedMimeType = detectMimeType(bytes);
    if (filename.trim().isEmpty ||
        !_supportedMimeTypes.contains(mimeType) ||
        detectedMimeType == null ||
        detectedMimeType != mimeType) {
      return AvatarUploadValidationError.unsupportedFormat;
    }
    return null;
  }

  /// Detecta el formato a partir de las firmas de los formatos admitidos.
  ///
  /// No reemplaza la validación de contenido del backend, pero evita confiar
  /// únicamente en el MIME que informa el cliente para seleccionar el tipo
  /// multipart que se envía.
  static String? detectMimeType(Uint8List bytes) {
    if (bytes.lengthInBytes >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.lengthInBytes >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'image/png';
    }
    if (bytes.lengthInBytes >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  /// Normaliza el MIME que informa el selector. Si ese valor no es útil, se
  /// usa una extensión admitida como metadato de respaldo; los bytes son la
  /// fuente de verdad durante la validación.
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
      default:
        return switch (filename.split('.').last.toLowerCase()) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => null,
        };
    }
  }

  /// El nombre adjunto no necesita conservar la extensión original: iOS puede
  /// recodificar HEIC a JPEG. Además se eliminan separadores y caracteres que
  /// no son seguros para un nombre multipart.
  static String filenameForMimeType({
    required String filename,
    required String mimeType,
  }) {
    final extension = switch (mimeType) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'bin',
    };
    final leafName = filename.split(RegExp(r'[/\\]')).last.trim();
    final stem = leafName
        .replaceFirst(RegExp(r'\.[^.]*$'), '')
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '${stem.isEmpty ? 'avatar' : stem}.$extension';
  }
}
