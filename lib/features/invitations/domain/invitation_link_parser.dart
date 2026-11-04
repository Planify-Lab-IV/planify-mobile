class InvitationLinkParser {
  static const String scheme = 'planify';
  static const String host = 'invite';
  static const String webInviteParameter = 'invite';

  /// Valida y extrae el token de invitación a partir de un [Uri].

  /// Los patrones aceptados son:
  /// - `planify://invite/<token>`
  /// - `https://<host>/?invite=<token>`
  /// Retorna el token en formato [String], o `null` si el URI no coincide
  /// con el esquema/host o no incluye un token no vacío.
  static String? parseToken(Uri uri) {
    if (_isNativeInvitationLink(uri)) {
      return _parseNativeToken(uri);
    }

    if (_isWebInvitationLink(uri)) {
      final tokens = uri.queryParametersAll[webInviteParameter];
      if (tokens == null || tokens.length != 1) return null;

      final token = tokens.single.trim();
      return token.isEmpty ? null : token;
    }

    return null;
  }

  /// Construye el enlace que debe compartirse a partir de la URL que devuelve
  /// el backend. En Android conserva el deep link existente; en Web crea una
  /// URL HTTPS de raíz con el token como query parameter.
  static String buildShareUrl({
    required String invitationUrl,
    required bool isWeb,
    required Uri webBaseUri,
  }) {
    final invitationUri = Uri.tryParse(invitationUrl);
    final token = invitationUri == null
        ? null
        : _parseNativeToken(invitationUri);
    if (token == null) {
      throw const FormatException('Invalid invitation URL returned by backend');
    }

    if (!isWeb) return invitationUrl;

    if (webBaseUri.scheme.toLowerCase() != 'https' || webBaseUri.host.isEmpty) {
      throw ArgumentError.value(
        webBaseUri,
        'webBaseUri',
        'A public HTTPS web origin is required',
      );
    }

    return Uri(
      scheme: 'https',
      host: webBaseUri.host,
      port: webBaseUri.hasPort ? webBaseUri.port : null,
      path: '/',
      queryParameters: {webInviteParameter: token},
    ).toString();
  }

  static String? _parseNativeToken(Uri uri) {
    if (!_isNativeInvitationLink(uri)) return null;

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
    return _isNativeInvitationLink(uri) || _isWebInvitationLink(uri);
  }

  static bool _isNativeInvitationLink(Uri uri) {
    return uri.scheme.toLowerCase() == scheme && uri.host.toLowerCase() == host;
  }

  static bool _isWebInvitationLink(Uri uri) {
    return uri.scheme.toLowerCase() == 'https' &&
        (uri.path.isEmpty || uri.path == '/') &&
        uri.queryParametersAll.containsKey(webInviteParameter);
  }
}
