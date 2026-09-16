import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../detail/controllers/events_providers.dart';
import 'schedule_confirmation_notifier.dart';
import 'schedule_confirmation_state.dart';

final scheduleConfirmationNotifierProvider = StateNotifierProvider.autoDispose
    .family<ScheduleConfirmationNotifier, ScheduleConfirmationState, String>(
      (ref, eventId) {
        return ScheduleConfirmationNotifier(
          repository: ref.watch(eventsRepositoryProvider),
          eventId: eventId,
        );
      },
    );
