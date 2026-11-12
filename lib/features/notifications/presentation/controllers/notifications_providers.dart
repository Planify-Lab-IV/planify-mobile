import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/http_notifications_repository.dart';
import '../../domain/notifications_repository.dart';
import 'push_device_operations.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return HttpNotificationsRepository(dio: ref.watch(dioClientProvider));
});

final pushDeviceOperationsProvider = Provider<PushDeviceOperations>(
  (ref) => PushDeviceOperations(ref.watch(notificationsRepositoryProvider)),
);
