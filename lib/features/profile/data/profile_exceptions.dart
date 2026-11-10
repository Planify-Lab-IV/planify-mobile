import '../domain/avatar_upload.dart';

sealed class ProfileException implements Exception {
  const ProfileException();
}

class InvalidAvatarFileException extends ProfileException {
  final AvatarUploadValidationError reason;

  const InvalidAvatarFileException(this.reason);
}

class NetworkProfileException extends ProfileException {
  const NetworkProfileException();
}

class InvalidProfileResponseException extends ProfileException {
  const InvalidProfileResponseException();
}

class InvalidProfileDataException extends ProfileException {
  const InvalidProfileDataException();
}

class AvatarStorageUnavailableException extends ProfileException {
  const AvatarStorageUnavailableException();
}
