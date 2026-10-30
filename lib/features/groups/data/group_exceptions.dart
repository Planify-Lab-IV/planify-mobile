sealed class GroupsException implements Exception {
  const GroupsException();
}

class NetworkGroupsException extends GroupsException {
  const NetworkGroupsException();
}

class InvalidGroupsResponseException extends GroupsException {
  const InvalidGroupsResponseException();
}

class GroupForbiddenException extends GroupsException {
  const GroupForbiddenException();
}

class GroupNotFoundException extends GroupsException {
  const GroupNotFoundException();
}

class InvalidGroupDataException extends GroupsException {
  const InvalidGroupDataException();
}
