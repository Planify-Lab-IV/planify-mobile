import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../activity_log/presentation/controllers/activity_log_providers.dart';
import '../../../auth/domain/user_session.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../../events/detail/screens/event_detail_screen.dart';

/// Abre el evento solo si sigue activa la sesión que recibió la notificación.
Future<void> openPushEvent({
  required WidgetRef ref,
  required GlobalKey<NavigatorState> navigatorKey,
  required bool Function() isMounted,
  required String eventId,
  required String sessionToken,
}) async {
  final resolvedEventId = eventId.trim();
  if (!isMounted() || resolvedEventId.isEmpty) return;

  final auth = ref.read(authNotifierProvider);
  if (auth is! AuthAuthenticated ||
      auth.session is! OrganizerSession ||
      auth.session.token != sessionToken) {
    return;
  }

  final navigator = navigatorKey.currentState;
  if (navigator == null) return;
  await navigator.push<void>(
    MaterialPageRoute(
      builder: (_) => EventDetailScreen(eventId: resolvedEventId),
    ),
  );
  if (isMounted()) ref.invalidate(unreadCountsProvider);
}
