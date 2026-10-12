import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/avatar_picker.dart';
import '../../data/fake_profile_repository.dart';
import '../../domain/profile_repository.dart';
import '../../domain/user_profile.dart';
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
  // El id es la dependencia reactiva: un cambio de cuenta crea un perfil
  // aislado, mientras que actualizar el nombre de la misma sesión lo conserva.
  final ownerId = ref.watch(_profileOwnerIdProvider);
  final authState = ref.read(authNotifierProvider);
  final session = switch (authState) {
    AuthAuthenticated(session: final OrganizerSession session)
        when session.userId == ownerId =>
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
});

final avatarPickerProvider = Provider<AvatarPicker>((ref) {
  return ImagePickerAvatarPicker();
});

final profileNotifierProvider =
    StateNotifierProvider.autoDispose<ProfileNotifier, ProfileState>((ref) {
      return ProfileNotifier(repository: ref.watch(profileRepositoryProvider));
    });
