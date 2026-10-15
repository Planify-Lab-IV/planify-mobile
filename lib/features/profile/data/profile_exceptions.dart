sealed class ProfileException implements Exception {
  const ProfileException();
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
