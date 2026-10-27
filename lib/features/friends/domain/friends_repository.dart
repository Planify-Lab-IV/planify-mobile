import 'friend_request.dart';
import 'friend_requests.dart';
import 'person.dart';

abstract interface class FriendsRepository {
  Future<List<Person>> search(String query);
  Future<FriendRequest> sendRequest(String userId);
  Future<FriendRequests> getRequests();
  Future<void> acceptRequest(String requestId);
  Future<void> removeRequest(String requestId);
  Future<List<Person>> getFriends();
}
