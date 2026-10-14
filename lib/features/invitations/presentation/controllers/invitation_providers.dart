import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/http_invitations_repository.dart';
import '../../domain/invitations_repository.dart';
import 'invitation_notifier.dart';
import 'invitation_state.dart';

final invitationsRepositoryProvider = Provider<InvitationsRepository>((ref) {
  return HttpInvitationsRepository(dio: ref.watch(dioClientProvider));
});

/// Provider del estado de invitaciones procesadas por Deep Link.
final invitationNotifierProvider =
    StateNotifierProvider<InvitationNotifier, InvitationState>((ref) {
      final repository = ref.watch(invitationsRepositoryProvider);
      return InvitationNotifier(repository);
    });
