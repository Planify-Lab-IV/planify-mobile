sealed class FriendsException implements Exception {
  const FriendsException();
}

class NetworkFriendsException extends FriendsException {
  const NetworkFriendsException();
}

class InvalidFriendsResponseException extends FriendsException {
  const InvalidFriendsResponseException();
}

class FriendsOperationException extends FriendsException {
  const FriendsOperationException();
}

class FriendshipAlreadyExistsException extends FriendsException {
  const FriendshipAlreadyExistsException();
}

class FriendRequestNotFoundException extends FriendsException {
  const FriendRequestNotFoundException();
}
