import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import '../../../auth/domain/user_session.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../domain/notifications_repository.dart';
import '../../data/push_permission_store.dart';
import 'notifications_providers.dart';
import 'push_device_operations.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/push_messaging_service.dart';

class PushRegistrationNotifier with WidgetsBindingObserver {
  final PushDeviceOperations _operations;
  final PushMessagingService _pushMessagingService;
  final PushPermissionStore _permissionStore;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _organizerSessionActive = false;
  int _activationVersion = 0;
  int? _checkingVersion;
  String? _sessionToken;
  bool _permissionReady = false;
  Future<bool>? _permissionRequest;

  PushRegistrationNotifier({
    required NotificationsRepository repository,
    required this._pushMessagingService,
    PushDeviceOperations? operations,
    PushPermissionStore? permissionStore,
  }) : _operations = operations ?? PushDeviceOperations(repository),
       _permissionStore = permissionStore ?? MemoryPushPermissionStore();

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

    final sessionToken = next.session.token;
    if (_organizerSessionActive && _sessionToken == sessionToken) return;
    if (_organizerSessionActive) _deactivate();
    _organizerSessionActive = true;
    _sessionToken = sessionToken;
    final activationVersion = ++_activationVersion;
    await _activate(activationVersion, sessionToken, allowRequest: true);
  }

  Future<void> _activate(
    int activationVersion,
    String sessionToken, {
    required bool allowRequest,
  }) async {
    if (_checkingVersion == activationVersion) return;
    _checkingVersion = activationVersion;
    try {
      var permissionGranted = await _pushMessagingService.hasPermission();
      if (!permissionGranted &&
          allowRequest &&
          !await _permissionStore.wasRequested()) {
        if (!_isCurrentActivation(activationVersion)) return;
        final request = _permissionRequest ??= _requestPermissionOnce();
        try {
          permissionGranted = await request;
        } finally {
          if (identical(_permissionRequest, request)) _permissionRequest = null;
        }
      }
      if (!_isCurrentActivation(activationVersion) || !permissionGranted) {
        if (_isCurrentActivation(activationVersion)) {
          _permissionReady = false;
          final subscription = _tokenRefreshSubscription;
          _tokenRefreshSubscription = null;
          unawaited(subscription?.cancel());
        }
        return;
      }

      if (_permissionReady) return;
      _permissionReady = true;

      _tokenRefreshSubscription ??= _pushMessagingService.onTokenRefresh.listen(
        (pushToken) {
          if (_isCurrentActivation(activationVersion)) {
            unawaited(_registerToken(pushToken, sessionToken));
          }
        },
        onError: (_, _) {},
      );

      final pushToken = await _pushMessagingService.getToken();
      if (!_isCurrentActivation(activationVersion) || pushToken == null) {
        return;
      }
      await _registerToken(pushToken, sessionToken);
    } catch (_) {
      // Registrar un dispositivo nunca debe afectar el inicio de sesión.
    } finally {
      if (_checkingVersion == activationVersion) _checkingVersion = null;
    }
  }

  Future<bool> _requestPermissionOnce() async {
    final granted = await _pushMessagingService.requestPermission();
    await _permissionStore.markRequested();
    return granted;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _organizerSessionActive &&
        _sessionToken != null) {
      unawaited(
        _activate(_activationVersion, _sessionToken!, allowRequest: false),
      );
    }
  }

  Future<void> _registerToken(String pushToken, String sessionToken) async {
    if (pushToken.trim().isEmpty) return;

    try {
      await _operations.register(pushToken, sessionToken);
    } catch (_) {
      // Se reintentará cuando la app restaure la sesión en el próximo inicio.
    }
  }

  bool _isCurrentActivation(int activationVersion) {
    return _organizerSessionActive && activationVersion == _activationVersion;
  }

  void _deactivate() {
    _organizerSessionActive = false;
    _permissionReady = false;
    _sessionToken = null;
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
    operations: ref.watch(pushDeviceOperationsProvider),
    permissionStore: PersistentPushPermissionStore(),
    pushMessagingService: ref.watch(pushMessagingServiceProvider),
  );
  ref.listen<AuthState>(
    authNotifierProvider,
    notifier.handleAuthStateChange,
    fireImmediately: true,
  );
  WidgetsBinding.instance.addObserver(notifier);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(notifier);
    notifier.dispose();
  });
  return notifier;
});
