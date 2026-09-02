import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../domain/event_draft.dart';
import 'create_event_notifier.dart';
import 'event_creation_state.dart';
import 'event_draft_notifier.dart';
import 'events_providers.dart';

export 'events_providers.dart' show eventsRepositoryProvider;

final eventDraftProvider =
    StateNotifierProvider<EventDraftNotifier, EventDraft>((ref) {
      return EventDraftNotifier();
    });

final createEventNotifierProvider =
    StateNotifierProvider<CreateEventNotifier, EventCreationState>((ref) {
      final repository = ref.watch(eventsRepositoryProvider);
      final authState = ref.watch(authNotifierProvider);
      final organizerId = authState is AuthAuthenticated
          ? authState.session.userId
          : '';

      return CreateEventNotifier(repository, organizerId);
    });
