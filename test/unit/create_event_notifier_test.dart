import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/domain/event_draft.dart';
import 'package:planify/features/events/presentation/controllers/create_event_notifier.dart';
import 'package:planify/features/events/presentation/controllers/event_creation_state.dart';

void main() {
  group('CreateEventNotifier', () {
    late FakeEventsRepository repository;
    late CreateEventNotifier notifier;

    setUp(() {
      repository = FakeEventsRepository(delay: Duration.zero);
      notifier = CreateEventNotifier(repository);
    });

    test('estado inicial es EventCreationInitial', () {
      expect(notifier.state, isA<EventCreationInitial>());
    });

    test('createEvent exitoso pasa a EventCreationSuccess', () async {
      const draft = EventDraft(
        name: 'Cumpleaños',
        location: 'Casa',
        selectedGroupId: 'grp-1',
        selectedGroupName: 'Amigos',
      );

      await notifier.createEvent(draft);

      expect(notifier.state, isA<EventCreationSuccess>());
      final successState = notifier.state as EventCreationSuccess;
      expect(successState.event.name, equals('Cumpleaños'));
      expect(successState.event.groupName, equals('Amigos'));
    });

    test('createEvent fallido pasa a EventCreationError', () async {
      final errorRepo = FakeEventsRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      );
      final errorNotifier = CreateEventNotifier(errorRepo);

      const draft = EventDraft(
        name: 'Cumpleaños',
        location: 'Casa',
        selectedGroupId: 'grp-1',
      );

      await errorNotifier.createEvent(draft);

      expect(errorNotifier.state, isA<EventCreationError>());
      final errorState = errorNotifier.state as EventCreationError;
      expect(errorState.message, isNotEmpty);
    });

    test('resetState restablece a EventCreationInitial', () async {
      const draft = EventDraft(
        name: 'Cumpleaños',
        location: 'Casa',
        selectedGroupId: 'grp-1',
      );

      await notifier.createEvent(draft);
      expect(notifier.state, isA<EventCreationSuccess>());

      notifier.resetState();
      expect(notifier.state, isA<EventCreationInitial>());
    });
  });
}
