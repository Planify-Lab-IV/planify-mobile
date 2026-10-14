sealed class GroupsException implements Exception {
  const GroupsException();
}

class NetworkGroupsException extends GroupsException {
  const NetworkGroupsException();
}

class InvalidGroupsResponseException extends GroupsException {
  const InvalidGroupsResponseException();
}
