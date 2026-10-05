final RegExp _usernamePattern = RegExp(r'^[a-z0-9_]{3,30}$');
final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidRegistrationName(String value) {
  return value.length >= 1 && value.length <= 80;
}

bool isValidRegistrationUsername(String value) {
  return _usernamePattern.hasMatch(value);
}

bool isValidRegistrationEmail(String value) {
  return _emailPattern.hasMatch(value);
}

bool isValidRegistrationPassword(String value) {
  return value.length >= 8 && value.length <= 72;
}
