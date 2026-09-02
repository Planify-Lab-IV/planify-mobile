import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/fake_invitations_repository.dart';
import '../../domain/invitations_repository.dart';
import 'invitation_notifier.dart';
import 'invitation_state.dart';

/// Punto de extensión: una vez mergeado PLANIFY-33, este provider puede reemplazarse
/// por una implementación real basada en Dio (ej. `HttpInvitationsRepository`).
final invitationsRepositoryProvider = Provider<InvitationsRepository>((ref) {
  return FakeInvitationsRepository();
});

/// Provider del estado de invitaciones procesadas por Deep Link.
final invitationNotifierProvider =
    StateNotifierProvider<InvitationNotifier, InvitationState>((ref) {
      final repository = ref.watch(invitationsRepositoryProvider);
      return InvitationNotifier(repository);
    });
