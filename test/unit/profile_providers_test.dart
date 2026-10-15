import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/auth/presentation/controllers/auth_state.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/profile/data/fake_profile_repository.dart';
import 'package:planify/features/profile/presentation/controllers/profile_providers.dart';
import 'package:planify/features/profile/data/http_profile_repository.dart';
import 'package:planify/features/profile/domain/user_profile.dart';

void main() {
  test('crea el repositorio HTTP con el cliente Dio compartido', () {
    final dio = Dio();
    final container = ProviderContainer(
      overrides: [dioClientProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);

    final repository = container.read(profileRepositoryProvider);

    expect(repository, isA<HttpProfileRepository>());
    expect((repository as HttpProfileRepository).dio, same(dio));
  });

  test('reinicia el perfil y el borrador al cambiar de cuenta', () async {
    final storage = FakeSecureStorage();
    final authRepository = FakeAuthRepository(
      storage: storage,
      delay: Duration.zero,
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        secureStorageProvider.overrideWithValue(storage),
        profileRepositoryProvider.overrideWith((ref) {
          final state = ref.watch(authNotifierProvider);
          final session = switch (state) {
            AuthAuthenticated(session: final OrganizerSession session) =>
              session,
            _ => null,
          };
          return FakeProfileRepository(
            delay: Duration.zero,
            initialProfile: session == null
                ? null
                : UserProfile(
                    name: session.name,
                    username: session.username,
                    email: session.email,
                  ),
          );
        }),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(profileNotifierProvider, (_, _) {});
    addTearDown(subscription.close);

    await container
        .read(authNotifierProvider.notifier)
        .login(identifier: 'alice', password: 'password123');
    await container.read(profileNotifierProvider.notifier).load();

    final aliceNotifier = container.read(profileNotifierProvider.notifier);
    aliceNotifier.updateDraftName('Alice Personal');
    aliceNotifier.selectAvatar('/tmp/alice-avatar.jpg');

    await container.read(authNotifierProvider.notifier).logout();
    await container
        .read(authNotifierProvider.notifier)
        .login(identifier: 'bob', password: 'password123');
    await container.read(profileNotifierProvider.notifier).load();

    final bobState = container.read(profileNotifierProvider);
    expect(bobState.profile?.name, 'bob');
    expect(bobState.draftName, 'bob');
    expect(bobState.pendingAvatarFilePath, isNull);
  });
}
