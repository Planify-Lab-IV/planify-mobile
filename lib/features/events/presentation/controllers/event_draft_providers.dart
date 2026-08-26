import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/event_draft.dart';
import 'event_draft_notifier.dart';

final eventDraftProvider =
    StateNotifierProvider<EventDraftNotifier, EventDraft>((ref) {
  return EventDraftNotifier();
});
