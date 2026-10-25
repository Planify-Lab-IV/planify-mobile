import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/push_messaging_service.dart';
import '../../../activity_log/presentation/controllers/activity_log_providers.dart';
import '../../../auth/domain/user_session.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../../events/detail/screens/event_detail_screen.dart';
import '../controllers/push_navigation_coordinator.dart';

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
      final auth = ref.read(authNotifierProvider);
      if (auth is! AuthAuthenticated ||
          auth.session is! OrganizerSession ||
          auth.session.token != sessionToken) {
        return;
      }
      final navigator = widget.navigatorKey.currentState;
      if (navigator == null) return;
      unawaited(_openEvent(navigator, eventId));
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _openEvent(NavigatorState navigator, String eventId) async {
    await navigator.push<void>(
      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventId)),
    );
    if (mounted) ref.invalidate(unreadCountsProvider);
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
