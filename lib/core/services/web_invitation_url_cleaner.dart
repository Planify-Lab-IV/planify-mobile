import 'package:flutter/foundation.dart';

import '../../features/invitations/domain/invitation_link_parser.dart';
import 'browser_url_replacer.dart';

/// Elimina el token de invitación de la URL actual sin recargar la app.
///
/// La limpieza se invoca tras la autenticación, para que el flujo de invitado
/// conserve la invitación resuelta mientras completa el login.
class WebInvitationUrlCleaner {
  final bool _isWeb;
  final Uri Function() _uriProvider;
  final void Function(Uri) _replaceUrl;

  WebInvitationUrlCleaner({
    bool? isWeb,
    Uri Function()? uriProvider,
    void Function(Uri)? replaceUrl,
  }) : _isWeb = isWeb ?? kIsWeb,
       _uriProvider = uriProvider ?? (() => Uri.base),
       _replaceUrl = replaceUrl ?? replaceBrowserUrl;

  void clearInviteQuery() {
    if (!_isWeb) return;

    final currentUri = _uriProvider();
    if (!currentUri.queryParametersAll.containsKey(
      InvitationLinkParser.webInviteParameter,
    )) {
      return;
    }

    final remainingParameters = <String, dynamic>{
      ...currentUri.queryParametersAll,
    }..remove(InvitationLinkParser.webInviteParameter);
    if (remainingParameters.isNotEmpty) {
      _replaceUrl(currentUri.replace(queryParameters: remainingParameters));
      return;
    }

    _replaceUrl(
      Uri(
        scheme: currentUri.scheme,
        userInfo: currentUri.userInfo,
        host: currentUri.host,
        port: currentUri.hasPort ? currentUri.port : null,
        path: currentUri.path,
        fragment: currentUri.fragment.isEmpty ? null : currentUri.fragment,
      ),
    );
  }
}
