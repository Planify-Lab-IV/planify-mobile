import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fake_friends_repository.dart';
import '../../domain/friends_repository.dart';
import 'friends_notifier.dart';
import 'friends_state.dart';

// Punto único de reemplazo para la integración HTTP de PLANIFY-101.
final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FakeFriendsRepository();
});

final friendsNotifierProvider =
    StateNotifierProvider.autoDispose<FriendsNotifier, FriendsState>((ref) {
      return FriendsNotifier(repository: ref.watch(friendsRepositoryProvider));
    });
