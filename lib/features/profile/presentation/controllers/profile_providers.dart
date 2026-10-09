import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/avatar_picker.dart';
import '../../data/fake_profile_repository.dart';
import '../../domain/profile_repository.dart';
import 'profile_notifier.dart';
import 'profile_state.dart';

// Punto único de sustitución para la integración con el backend.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FakeProfileRepository();
});

final avatarPickerProvider = Provider<AvatarPicker>((ref) {
  return ImagePickerAvatarPicker();
});

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
      return ProfileNotifier(repository: ref.watch(profileRepositoryProvider));
    });
