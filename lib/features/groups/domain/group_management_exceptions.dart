sealed class GroupManagementException implements Exception {
  const GroupManagementException();
}

class GroupForbiddenException extends GroupManagementException {
  const GroupForbiddenException();
}

class GroupNotFoundException extends GroupManagementException {
  const GroupNotFoundException();
}

class InvalidGroupDataException extends GroupManagementException {
  const InvalidGroupDataException();
}

class GroupManagementOperationException extends GroupManagementException {
  const GroupManagementOperationException();
}
