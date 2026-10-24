import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/http_notifications_repository.dart';
import '../../domain/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return HttpNotificationsRepository(dio: ref.watch(dioClientProvider));
});
