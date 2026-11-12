import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/http_friends_repository.dart';
import '../../domain/friends_repository.dart';
import 'friends_notifier.dart';
import 'friends_state.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return HttpFriendsRepository(dio: ref.watch(dioClientProvider));
});

final friendsNotifierProvider =
    StateNotifierProvider.autoDispose<FriendsNotifier, FriendsState>((ref) {
      return FriendsNotifier(repository: ref.watch(friendsRepositoryProvider));
    });
