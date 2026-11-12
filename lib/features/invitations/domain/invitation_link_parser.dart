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

  /// Extrae un token solamente del formato que devuelve el backend actual.
  ///
  /// El repositorio usa este parser más estricto para conservar el contrato
  /// `planify://invite/<token>` aunque [parseToken] también acepte enlaces Web
  /// que la app recibe al abrirse.
  static String? parseNativeToken(Uri uri) => _parseNativeToken(uri);

  /// Construye el enlace que debe compartirse a partir de la URL que devuelve
  /// el backend. En Android conserva el deep link existente; en Web crea una
  /// URL HTTPS de raíz con el token como query parameter.
  ///
  /// La raíz y el origen de [webBaseUri] son intencionales: PLANIFY-161 define
  /// que un enlace compartido cargue la app desde raíz y que los previews de
  /// Hosting compartan su propio origen. La app no se sirve bajo subpaths.
  static String buildShareUrl({
    required String invitationUrl,
    required bool isWeb,
    Uri? webBaseUri,
  }) {
    final invitationUri = Uri.tryParse(invitationUrl);
    final token = invitationUri == null
        ? null
        : _parseNativeToken(invitationUri);
    if (token == null) {
      throw const FormatException('Invalid invitation URL returned by backend');
    }

    if (!isWeb) return invitationUrl;

    if (webBaseUri == null ||
        webBaseUri.scheme.toLowerCase() != 'https' ||
        webBaseUri.host.isEmpty) {
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

  /// Acepta cualquier origen HTTPS para que el mismo parser funcione tanto en
  /// producción como en previews de Hosting. No redirige ni navega a ese
  /// origen: solo extrae el token para resolverlo contra la API configurada.
  /// Restringir hosts requeriría una configuración canónica de entornos.
  static bool _isWebInvitationLink(Uri uri) {
    return uri.scheme.toLowerCase() == 'https' &&
        (uri.path.isEmpty || uri.path == '/') &&
        uri.queryParametersAll.containsKey(webInviteParameter);
  }
}
