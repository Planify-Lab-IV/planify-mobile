import '../../domain/avatar_upload.dart';
import '../../domain/user_profile.dart';

enum ProfileLoadStatus { loading, success, error }

enum ProfileSaveStatus { idle, saving, error }

enum ProfileSaveFailure {
  none,
  generic,
  network,
  avatarInvalidFormat,
  avatarTooLarge,
  avatarStorageUnavailable,
}

class ProfileState {
  final UserProfile? profile;
  final String draftName;
  final AvatarUpload? pendingAvatar;
  final AvatarUpload? savedAvatarPreview;
  final ProfileLoadStatus loadStatus;
  final ProfileSaveStatus saveStatus;
  final ProfileSaveFailure saveFailure;

  const ProfileState({
    this.profile,
    this.draftName = '',
    this.pendingAvatar,
    this.savedAvatarPreview,
    this.loadStatus = ProfileLoadStatus.loading,
    this.saveStatus = ProfileSaveStatus.idle,
    this.saveFailure = ProfileSaveFailure.none,
  });

  bool get isLoading => loadStatus == ProfileLoadStatus.loading;
  bool get hasLoadError => loadStatus == ProfileLoadStatus.error;
  bool get isSaving => saveStatus == ProfileSaveStatus.saving;
  bool get hasSaveError => saveStatus == ProfileSaveStatus.error;

  String get trimmedDraftName => draftName.trim();

  bool get hasPendingChanges {
    final savedProfile = profile;
    if (savedProfile == null) return false;

    return trimmedDraftName != savedProfile.name || pendingAvatar != null;
  }

  bool get canSave =>
      !isSaving &&
      hasPendingChanges &&
      trimmedDraftName.isNotEmpty &&
      trimmedDraftName.length <= 80;

  ProfileState copyWith({
    UserProfile? profile,
    String? draftName,
    AvatarUpload? pendingAvatar,
    AvatarUpload? savedAvatarPreview,
    bool clearPendingAvatar = false,
    ProfileLoadStatus? loadStatus,
    ProfileSaveStatus? saveStatus,
    ProfileSaveFailure? saveFailure,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      draftName: draftName ?? this.draftName,
      pendingAvatar: clearPendingAvatar
          ? null
          : pendingAvatar ?? this.pendingAvatar,
      savedAvatarPreview: savedAvatarPreview ?? this.savedAvatarPreview,
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      saveFailure: saveFailure ?? this.saveFailure,
    );
  }
}
