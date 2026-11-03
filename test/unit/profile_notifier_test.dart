import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/profile/data/fake_profile_repository.dart';
import 'package:planify/features/profile/data/profile_exceptions.dart';
import 'package:planify/features/profile/domain/avatar_upload.dart';
import 'package:planify/features/profile/domain/user_profile.dart';
import 'package:planify/features/profile/presentation/controllers/profile_notifier.dart';
import 'package:planify/features/profile/presentation/controllers/profile_state.dart';

void main() {
  const profile = UserProfile(
    name: 'Juan Pérez',
    username: 'juan.perez',
    email: 'juan@example.com',
  );
  final avatar = AvatarUpload(
    bytes: Uint8List.fromList([1, 2, 3]),
    filename: 'avatar.webp',
    mimeType: 'image/webp',
  );

  group('ProfileState', () {
    test('detecta cambios de nombre y avatar seleccionados', () {
      final state = ProfileState(
        profile: profile,
        draftName: '  Juan Pérez  ',
        pendingAvatar: avatar,
        loadStatus: ProfileLoadStatus.success,
      );

      expect(state.hasPendingChanges, isTrue);
      expect(state.canSave, isTrue);
    });

    test('canSave exige nombre válido y cambios pendientes', () {
      final blank = ProfileState(
        profile: profile,
        draftName: '   ',
        pendingAvatar: avatar,
        loadStatus: ProfileLoadStatus.success,
      );
      final tooLong = ProfileState(
        profile: profile,
        draftName: 'a' * 81,
        loadStatus: ProfileLoadStatus.success,
      );

      expect(blank.canSave, isFalse);
      expect(tooLong.canSave, isFalse);
    });
  });

  group('ProfileNotifier', () {
    late FakeProfileRepository repository;
    late ProfileNotifier notifier;

    setUp(() async {
      repository = FakeProfileRepository(
        delay: Duration.zero,
        initialProfile: profile,
      );
      notifier = ProfileNotifier(repository: repository);
      await notifier.load();
    });

    tearDown(() => notifier.dispose());

    test('guarda el nombre y avatar seleccionados', () async {
      notifier.updateDraftName('  Juan García  ');
      notifier.selectAvatar(avatar);

      await notifier.save();

      expect(notifier.state.saveStatus, ProfileSaveStatus.idle);
      expect(notifier.state.profile?.name, 'Juan García');
      expect(
        notifier.state.profile?.avatarUrl,
        'https://fake.planify.test/avatars/avatar.webp',
      );
      expect(notifier.state.pendingAvatar, isNull);
    });

    test('conserva borrador y avatar cuando guardar falla', () async {
      notifier.updateDraftName('Juan García');
      notifier.selectAvatar(avatar);
      repository.shouldThrowError = true;

      await notifier.save();

      expect(notifier.state.saveStatus, ProfileSaveStatus.error);
      expect(notifier.state.draftName, 'Juan García');
      expect(notifier.state.pendingAvatar, same(avatar));
      expect(notifier.state.saveFailure, ProfileSaveFailure.generic);
    });

    test('clasifica error de red y conserva el nombre editado', () async {
      final failingNotifier = ProfileNotifier(
        repository: _FailingAvatarRepository(
          profile,
          const NetworkProfileException(),
        ),
      );
      await failingNotifier.load();
      failingNotifier.updateDraftName('Juan García');
      failingNotifier.selectAvatar(avatar);

      await failingNotifier.save();

      expect(failingNotifier.state.saveFailure, ProfileSaveFailure.network);
      expect(failingNotifier.state.draftName, 'Juan García');
      expect(failingNotifier.state.pendingAvatar, same(avatar));
      failingNotifier.dispose();
    });

    test(
      'distingue almacenamiento no disponible y permite descartar avatar',
      () async {
        final unavailableNotifier = ProfileNotifier(
          repository: _FailingAvatarRepository(
            profile,
            const AvatarStorageUnavailableException(),
          ),
        );
        await unavailableNotifier.load();
        unavailableNotifier.selectAvatar(avatar);

        await unavailableNotifier.save();
        unavailableNotifier.discardPendingAvatar();

        expect(unavailableNotifier.state.saveFailure, ProfileSaveFailure.none);
        expect(unavailableNotifier.state.pendingAvatar, isNull);
        unavailableNotifier.dispose();
      },
    );
  });
}

class _FailingAvatarRepository extends FakeProfileRepository {
  final Exception error;

  _FailingAvatarRepository(UserProfile profile, this.error)
    : super(delay: Duration.zero, initialProfile: profile);

  @override
  Future<UserProfile> updateProfile({String? name, AvatarUpload? avatar}) {
    throw error;
  }
}
