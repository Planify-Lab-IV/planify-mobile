class InvitationLinkParser {
  static const String scheme = 'planify';
  static const String host = 'invite';

  /// Valida y extrae el token de invitación a partir de un [Uri].

  /// El patrón esperado es: `planify://invite/<token>`
  /// Retorna el token en formato [String], o `null` si el URI no coincide
  /// con el esquema/host o no incluye un token no vacío.
  static String? parseToken(Uri uri) {
    if (uri.scheme.toLowerCase() != scheme) {
      return null;
    }

    if (uri.host.toLowerCase() != host) {
      return null;
    }

    final segments = uri.pathSegments
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return null;
    }

    return segments.first;
  }

  /// Determina si un [Uri] pertenece al esquema y host de invitaciones de Planify,
  /// independientemente de si el token está presente o no.
  static bool isInvitationLink(Uri uri) {
    return uri.scheme.toLowerCase() == scheme && uri.host.toLowerCase() == host;
  }
}
