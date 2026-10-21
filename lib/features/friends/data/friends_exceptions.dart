sealed class FriendsException implements Exception {
  const FriendsException();
}

class FriendsOperationException extends FriendsException {
  const FriendsOperationException();
}

class FriendRequestNotFoundException extends FriendsException {
  const FriendRequestNotFoundException();
}
