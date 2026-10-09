import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/profile/data/fake_profile_repository.dart';
import 'package:planify/features/profile/domain/user_profile.dart';
import 'package:planify/features/profile/presentation/controllers/profile_notifier.dart';
import 'package:planify/features/profile/presentation/controllers/profile_state.dart';

void main() {
  const profile = UserProfile(
    name: 'Juan Pérez',
    username: 'juan.perez',
    email: 'juan@example.com',
  );

  group('ProfileState', () {
    test('detecta cambios de nombre usando su valor sin espacios externos', () {
      const unchanged = ProfileState(
        profile: profile,
        draftName: '  Juan Pérez  ',
        loadStatus: ProfileLoadStatus.success,
      );
      const changed = ProfileState(
        profile: profile,
        draftName: 'Juan García',
        loadStatus: ProfileLoadStatus.success,
      );

      expect(unchanged.hasPendingChanges, isFalse);
      expect(changed.hasPendingChanges, isTrue);
    });

    test('detecta una nueva imagen como cambio pendiente', () {
      const state = ProfileState(
        profile: profile,
        draftName: 'Juan Pérez',
        pendingAvatarFilePath: '/tmp/avatar.png',
        loadStatus: ProfileLoadStatus.success,
      );

      expect(state.hasPendingChanges, isTrue);
      expect(state.canSave, isTrue);
    });

    test('canSave exige cambios y un nombre entre 1 y 80 caracteres', () {
      const noChanges = ProfileState(
        profile: profile,
        draftName: 'Juan Pérez',
        loadStatus: ProfileLoadStatus.success,
      );
      const blank = ProfileState(
        profile: profile,
        draftName: '   ',
        pendingAvatarFilePath: '/tmp/avatar.png',
        loadStatus: ProfileLoadStatus.success,
      );
      final oneCharacter = ProfileState(
        profile: profile,
        draftName: 'J',
        loadStatus: ProfileLoadStatus.success,
      );
      final eightyCharacters = ProfileState(
        profile: profile,
        draftName: 'a' * 80,
        loadStatus: ProfileLoadStatus.success,
      );
      final tooLong = ProfileState(
        profile: profile,
        draftName: 'a' * 81,
        loadStatus: ProfileLoadStatus.success,
      );
      const saving = ProfileState(
        profile: profile,
        draftName: 'Juan García',
        loadStatus: ProfileLoadStatus.success,
        saveStatus: ProfileSaveStatus.saving,
      );

      expect(noChanges.canSave, isFalse);
      expect(blank.canSave, isFalse);
      expect(oneCharacter.canSave, isTrue);
      expect(eightyCharacters.canSave, isTrue);
      expect(tooLong.canSave, isFalse);
      expect(saving.canSave, isFalse);
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

    test('carga el perfil y prepara el borrador con el nombre guardado', () {
      expect(notifier.state.profile, profile);
      expect(notifier.state.draftName, 'Juan Pérez');
      expect(notifier.state.loadStatus, ProfileLoadStatus.success);
    });

    test('guarda el nombre y la imagen seleccionada', () async {
      notifier.updateDraftName('  Juan García  ');
      notifier.selectAvatar('/tmp/avatar.webp');

      await notifier.save();

      expect(notifier.state.saveStatus, ProfileSaveStatus.idle);
      expect(notifier.state.profile?.name, 'Juan García');
      expect(notifier.state.profile?.avatarUrl, '/tmp/avatar.webp');
      expect(notifier.state.pendingAvatarFilePath, isNull);
      expect(await repository.getMyProfile(), notifier.state.profile);
    });

    test('conserva el borrador cuando guardar falla', () async {
      notifier.updateDraftName('Juan García');
      notifier.selectAvatar('/tmp/avatar.jpg');
      repository.shouldThrowError = true;

      await notifier.save();

      expect(notifier.state.saveStatus, ProfileSaveStatus.error);
      expect(notifier.state.draftName, 'Juan García');
      expect(notifier.state.pendingAvatarFilePath, '/tmp/avatar.jpg');
      expect(notifier.state.profile, profile);
    });

    test('expone un error de carga y permite reintentar', () async {
      final failingRepository = FakeProfileRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      );
      final failingNotifier = ProfileNotifier(repository: failingRepository);
      await failingNotifier.load();

      expect(failingNotifier.state.hasLoadError, isTrue);

      failingRepository.shouldThrowError = false;
      await failingNotifier.load();

      expect(failingNotifier.state.loadStatus, ProfileLoadStatus.success);
      failingNotifier.dispose();
    });
  });
}
