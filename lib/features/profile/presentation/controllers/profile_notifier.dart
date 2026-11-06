import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile_exceptions.dart';
import '../../domain/avatar_upload.dart';
import '../../domain/profile_repository.dart';
import 'profile_state.dart';

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository repository;

  ProfileNotifier({required this.repository}) : super(const ProfileState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(
      loadStatus: ProfileLoadStatus.loading,
      saveStatus: ProfileSaveStatus.idle,
      saveFailure: ProfileSaveFailure.none,
    );

    try {
      final profile = await repository.getMyProfile();
      if (!mounted) return;

      state = ProfileState(
        profile: profile,
        draftName: profile.name,
        loadStatus: ProfileLoadStatus.success,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loadStatus: ProfileLoadStatus.error);
    }
  }

  void updateDraftName(String name) {
    if (state.profile == null) return;

    state = state.copyWith(
      draftName: name,
      saveStatus: ProfileSaveStatus.idle,
      saveFailure: ProfileSaveFailure.none,
    );
  }

  void selectAvatar(AvatarUpload avatar) {
    if (state.profile == null) return;

    state = state.copyWith(
      pendingAvatar: avatar,
      saveStatus: ProfileSaveStatus.idle,
      saveFailure: ProfileSaveFailure.none,
    );
  }

  void discardPendingAvatar() {
    if (state.pendingAvatar == null) return;

    state = state.copyWith(
      clearPendingAvatar: true,
      saveStatus: ProfileSaveStatus.idle,
      saveFailure: ProfileSaveFailure.none,
    );
  }

  Future<void> save() async {
    final savedProfile = state.profile;
    if (savedProfile == null || !state.canSave) return;

    final name = state.trimmedDraftName;
    final requestedName = name == savedProfile.name ? null : name;
    final avatar = state.pendingAvatar;

    state = state.copyWith(
      saveStatus: ProfileSaveStatus.saving,
      saveFailure: ProfileSaveFailure.none,
    );
    try {
      final updatedProfile = await repository.updateProfile(
        name: requestedName,
        avatar: avatar,
      );
      if (!mounted) return;

      state = ProfileState(
        profile: updatedProfile,
        draftName: updatedProfile.name,
        loadStatus: ProfileLoadStatus.success,
        // La API normalmente devuelve la URL persistida. Si no lo hace (como
        // el fake en memoria), mantenemos los bytes confirmados hasta la
        // próxima carga en lugar de intentar cargar una URL ficticia.
        savedAvatarPreview: updatedProfile.avatarUrl == null
            ? avatar ?? state.savedAvatarPreview
            : null,
      );
    } on InvalidAvatarFileException catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        saveStatus: ProfileSaveStatus.error,
        saveFailure: switch (error.reason) {
          AvatarUploadValidationError.unsupportedFormat =>
            ProfileSaveFailure.avatarInvalidFormat,
          AvatarUploadValidationError.tooLarge =>
            ProfileSaveFailure.avatarTooLarge,
        },
      );
    } on NetworkProfileException {
      if (!mounted) return;
      state = state.copyWith(
        saveStatus: ProfileSaveStatus.error,
        saveFailure: ProfileSaveFailure.network,
      );
    } on AvatarStorageUnavailableException {
      if (!mounted) return;
      state = state.copyWith(
        saveStatus: ProfileSaveStatus.error,
        saveFailure: ProfileSaveFailure.avatarStorageUnavailable,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        saveStatus: ProfileSaveStatus.error,
        saveFailure: ProfileSaveFailure.generic,
      );
    }
  }
}
