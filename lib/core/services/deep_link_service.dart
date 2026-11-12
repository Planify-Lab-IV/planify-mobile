import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Servicio centralizado de Deep Links para toda la aplicación.
///
/// En plataformas nativas encapsula [AppLinks] para procesar el enlace inicial
/// y los enlaces entrantes. En Web lee [Uri.base] una vez al iniciar, ya que el
/// navegador no emite deep links nuevos para una pestaña que ya está abierta.
class DeepLinkService {
  final AppLinks _appLinks;
  final bool _isWeb;
  final Uri Function() _webUriProvider;
  StreamSubscription<Uri>? _subscription;

  DeepLinkService({
    AppLinks? appLinks,
    bool? isWeb,
    Uri Function()? webUriProvider,
  }) : _appLinks = appLinks ?? AppLinks(),
       _isWeb = isWeb ?? kIsWeb,
       _webUriProvider = webUriProvider ?? (() => Uri.base);

  AppLinks get appLinks => _appLinks;

  /// El callback recibe la URI de arranque o una URI entrante en plataformas
  /// nativas.
  Future<void> listen(void Function(Uri uri) onUriReceived) async {
    _subscription?.cancel();
    _subscription = null;

    if (_isWeb) {
      onUriReceived(_webUriProvider());
      return;
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) {
        onUriReceived(uri);
      },
      onError: (_) {
        // Manejo controlado de errores en el stream
      },
    );

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        onUriReceived(initialUri);
      }
    } catch (_) {
      // Ignora errores en la lectura inicial para proteger el arranque de la app
    }
  }

  /// Cancela la suscripción activa.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
