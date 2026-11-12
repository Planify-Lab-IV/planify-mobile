import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/features/friends/data/http_friends_repository.dart';
import 'package:planify/features/friends/presentation/controllers/friends_providers.dart';

void main() {
  test('friendsRepositoryProvider uses the injected HTTP client', () {
    final dio = Dio();
    final container = ProviderContainer(
      overrides: [dioClientProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);

    final repository = container.read(friendsRepositoryProvider);

    expect(repository, isA<HttpFriendsRepository>());
    expect((repository as HttpFriendsRepository).dio, same(dio));
  });
}
