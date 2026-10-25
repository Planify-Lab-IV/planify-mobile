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
import '../../../events/detail/screens/event_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
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
          onPressed: () => _openEvent(message.eventId, sessionToken),
        ),
      ),
    );
  }

  Future<void> _openEvent(String eventId, String sessionToken) async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated ||
        auth.session is! OrganizerSession ||
        auth.session.token != sessionToken) {
      return;
    }
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    await navigator.push<void>(
      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventId)),
    );
    if (mounted) ref.invalidate(unreadCountsProvider);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
