import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/avatar_picker.dart';
import '../../data/http_profile_repository.dart';
import '../../domain/profile_repository.dart';
import '../../../auth/domain/user_session.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import 'profile_notifier.dart';
import 'profile_state.dart';

final _profileOwnerIdProvider = Provider<String?>((ref) {
  return ref.watch(
    authNotifierProvider.select((state) {
      if (state case AuthAuthenticated(
        session: final OrganizerSession session,
      )) {
        return session.userId;
      }
      return null;
    }),
  );
});

// Punto único de sustitución para la integración con el backend.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  // El id es una dependencia reactiva: un cambio de cuenta recrea el
  // repositorio y el notifier asociado para no filtrar borradores entre ellas.
  ref.watch(_profileOwnerIdProvider);
  return HttpProfileRepository(dio: ref.watch(dioClientProvider));
});

final avatarPickerProvider = Provider<AvatarPicker>((ref) {
  return ImagePickerAvatarPicker();
});

final profileNotifierProvider =
    StateNotifierProvider.autoDispose<ProfileNotifier, ProfileState>((ref) {
      return ProfileNotifier(repository: ref.watch(profileRepositoryProvider));
    });
