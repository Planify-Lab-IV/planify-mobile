import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/push_messaging_service.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../controllers/push_navigation_coordinator.dart';
import 'push_event_navigator.dart';

class OpenedPushListener extends ConsumerStatefulWidget {
  const OpenedPushListener({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  ConsumerState<OpenedPushListener> createState() => _OpenedPushListenerState();
}

class _OpenedPushListenerState extends ConsumerState<OpenedPushListener> {
  late final PushNavigationCoordinator _coordinator;
  late final StreamSubscription<PushMessage> _subscription;
  late final ProviderSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _coordinator = PushNavigationCoordinator(
      initialAuthState: ref.read(authNotifierProvider),
      onNavigate: _scheduleNavigation,
    );
    _authSubscription = ref.listenManual<AuthState>(
      authNotifierProvider,
      (_, next) => _coordinator.handleAuthState(next),
    );
    final messaging = ref.read(pushMessagingServiceProvider);
    _subscription = messaging.onMessageOpened.listen(
      _coordinator.handleMessage,
      onError: (_, _) {},
    );
    unawaited(_readInitialMessage(messaging));
  }

  Future<void> _readInitialMessage(PushMessagingService messaging) async {
    try {
      final message = await messaging.getInitialMessage();
      if (mounted && message != null) _coordinator.handleMessage(message);
    } catch (_) {
      // Un error del SDK no debe interrumpir el arranque de la app.
    }
  }

  void _scheduleNavigation(String eventId, String sessionToken) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        openPushEvent(
          ref: ref,
          navigatorKey: widget.navigatorKey,
          isMounted: () => mounted,
          eventId: eventId,
          sessionToken: sessionToken,
        ),
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _authSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
