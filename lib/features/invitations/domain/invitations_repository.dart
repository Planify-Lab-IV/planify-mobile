abstract class InvitationsRepository {
  /// Crea una invitación para [eventId] y devuelve su URL para compartir.
  Future<String> createInvitation(String eventId);

  Future<String> resolveInvitationToken(String token);
}
