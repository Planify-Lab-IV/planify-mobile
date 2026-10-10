import '../../domain/user_profile.dart';

enum ProfileLoadStatus { loading, success, error }

enum ProfileSaveStatus { idle, saving, error }

class ProfileState {
  final UserProfile? profile;
  final String draftName;
  final String? pendingAvatarFilePath;
  final ProfileLoadStatus loadStatus;
  final ProfileSaveStatus saveStatus;

  const ProfileState({
    this.profile,
    this.draftName = '',
    this.pendingAvatarFilePath,
    this.loadStatus = ProfileLoadStatus.loading,
    this.saveStatus = ProfileSaveStatus.idle,
  });

  bool get isLoading => loadStatus == ProfileLoadStatus.loading;
  bool get hasLoadError => loadStatus == ProfileLoadStatus.error;
  bool get isSaving => saveStatus == ProfileSaveStatus.saving;
  bool get hasSaveError => saveStatus == ProfileSaveStatus.error;

  String get trimmedDraftName => draftName.trim();

  bool get hasPendingChanges {
    final savedProfile = profile;
    if (savedProfile == null) return false;

    return trimmedDraftName != savedProfile.name ||
        pendingAvatarFilePath != null;
  }

  bool get canSave =>
      !isSaving &&
      hasPendingChanges &&
      trimmedDraftName.isNotEmpty &&
      trimmedDraftName.length <= 80;

  ProfileState copyWith({
    UserProfile? profile,
    String? draftName,
    String? pendingAvatarFilePath,
    ProfileLoadStatus? loadStatus,
    ProfileSaveStatus? saveStatus,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      draftName: draftName ?? this.draftName,
      pendingAvatarFilePath:
          pendingAvatarFilePath ?? this.pendingAvatarFilePath,
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
    );
  }
}
