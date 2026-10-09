import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    state = state.copyWith(draftName: name, saveStatus: ProfileSaveStatus.idle);
  }

  void selectAvatar(String avatarFilePath) {
    if (state.profile == null) return;

    state = state.copyWith(
      pendingAvatarFilePath: avatarFilePath,
      saveStatus: ProfileSaveStatus.idle,
    );
  }

  Future<void> save() async {
    final savedProfile = state.profile;
    if (savedProfile == null || !state.canSave) return;

    final name = state.trimmedDraftName;
    final requestedName = name == savedProfile.name ? null : name;
    final avatarFilePath = state.pendingAvatarFilePath;

    state = state.copyWith(saveStatus: ProfileSaveStatus.saving);
    try {
      final updatedProfile = await repository.updateProfile(
        name: requestedName,
        avatarFilePath: avatarFilePath,
      );
      if (!mounted) return;

      state = ProfileState(
        profile: updatedProfile,
        draftName: updatedProfile.name,
        loadStatus: ProfileLoadStatus.success,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(saveStatus: ProfileSaveStatus.error);
    }
  }
}
