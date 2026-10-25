import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/user_session.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../domain/notifications_repository.dart';
import 'notifications_providers.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/push_messaging_service.dart';

class PushRegistrationNotifier {
  final NotificationsRepository _repository;
  final PushMessagingService _pushMessagingService;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _organizerSessionActive = false;
  int _activationVersion = 0;

  PushRegistrationNotifier({
    required this._repository,
    required this._pushMessagingService,
  });

  Future<void> handleAuthStateChange(
    AuthState? previous,
    AuthState next,
  ) async {
    final isOrganizerSession =
        next is AuthAuthenticated && next.session is OrganizerSession;
    if (!isOrganizerSession) {
      _deactivate();
      return;
    }

    if (_organizerSessionActive) return;
    _organizerSessionActive = true;
    final activationVersion = ++_activationVersion;
    await _activate(activationVersion);
  }

  Future<void> _activate(int activationVersion) async {
    try {
      final permissionGranted = await _pushMessagingService.requestPermission();
      if (!_isCurrentActivation(activationVersion) || !permissionGranted) {
        return;
      }

      _tokenRefreshSubscription ??= _pushMessagingService.onTokenRefresh.listen(
        (pushToken) {
          if (_isCurrentActivation(activationVersion)) {
            unawaited(_registerToken(pushToken));
          }
        },
        onError: (_, _) {},
      );

      final pushToken = await _pushMessagingService.getToken();
      if (!_isCurrentActivation(activationVersion) || pushToken == null) {
        return;
      }
      await _registerToken(pushToken);
    } catch (_) {
      // Registrar un dispositivo nunca debe afectar el inicio de sesión.
    }
  }

  Future<void> _registerToken(String pushToken) async {
    if (pushToken.trim().isEmpty) return;

    try {
      await _repository.registerDevice(pushToken);
    } catch (_) {
      // Se reintentará cuando la app restaure la sesión en el próximo inicio.
    }
  }

  bool _isCurrentActivation(int activationVersion) {
    return _organizerSessionActive && activationVersion == _activationVersion;
  }

  void _deactivate() {
    _organizerSessionActive = false;
    _activationVersion++;
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  void dispose() {
    _deactivate();
  }
}

final pushRegistrationNotifierProvider = Provider<PushRegistrationNotifier>((
  ref,
) {
  final notifier = PushRegistrationNotifier(
    repository: ref.watch(notificationsRepositoryProvider),
    pushMessagingService: ref.watch(pushMessagingServiceProvider),
  );
  ref.listen<AuthState>(
    authNotifierProvider,
    notifier.handleAuthStateChange,
    fireImmediately: true,
  );
  ref.onDispose(notifier.dispose);
  return notifier;
});
