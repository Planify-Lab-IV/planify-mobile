import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/push_messaging_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../activity_log/presentation/controllers/activity_log_providers.dart';
import '../../../auth/domain/user_session.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import 'push_event_navigator.dart';

class ForegroundPushListener extends ConsumerStatefulWidget {
  const ForegroundPushListener({
    super.key,
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Widget child;

  @override
  ConsumerState<ForegroundPushListener> createState() =>
      _ForegroundPushListenerState();
}

class _ForegroundPushListenerState
    extends ConsumerState<ForegroundPushListener> {
  late final StreamSubscription<PushMessage> _subscription;
  late final ProviderSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AuthState>(authNotifierProvider, (
      previous,
      next,
    ) {
      final oldSession =
          previous is AuthAuthenticated && previous.session is OrganizerSession
          ? previous.session
          : null;
      final newSession =
          next is AuthAuthenticated && next.session is OrganizerSession
          ? next.session
          : null;
      if (oldSession != null && oldSession.token != newSession?.token) {
        final messenger = widget.scaffoldMessengerKey.currentState;
        messenger?.clearSnackBars();
        messenger?.removeCurrentSnackBar();
        widget.navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });
    _subscription = ref
        .read(pushMessagingServiceProvider)
        .onForegroundMessage
        .listen(_showMessage, onError: (_, _) {});
  }

  void _showMessage(PushMessage message) {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated || auth.session is! OrganizerSession) return;

    ref.invalidate(unreadCountsProvider);
    final messenger = widget.scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    final sessionToken = auth.session.token;
    final localizations = AppLocalizations.of(messenger.context)!;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(message.body),
          ],
        ),
        action: SnackBarAction(
          label: localizations.pushNotificationViewAction,
          onPressed: () => openPushEvent(
            ref: ref,
            navigatorKey: widget.navigatorKey,
            isMounted: () => mounted,
            eventId: message.eventId,
            sessionToken: sessionToken,
          ),
        ),
      ),
    );
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
