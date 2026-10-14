import 'dart:async';
import 'package:app_links/app_links.dart';

/// Servicio centralizado de Deep Links para toda la aplicación.
///
/// Encapsula [AppLinks] y garantiza un único punto de escucha para:
/// 1. El enlace con el que se abrió la app (cold start).
/// 2. Enlaces entrantes mientras la app está en ejecución (foreground o background).
class DeepLinkService {
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  AppLinks get appLinks => _appLinks;

  // el parametro de la funcion es un callback que recibe una uri, devuelve void y
  // se invoca haciendo onUriReceived(uri)
  Future<void> listen(void Function(Uri uri) onUriReceived) async {
    _subscription?.cancel();
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
