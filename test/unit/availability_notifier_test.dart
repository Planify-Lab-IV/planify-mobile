import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/availability/data/fake_availability_repository.dart';
import 'package:planify/features/availability/domain/availability_heatmap_dto.dart';
import 'package:planify/features/availability/domain/availability_repository.dart';
import 'package:planify/features/availability/domain/slot.dart';
import 'package:planify/features/availability/presentation/controllers/availability_notifier.dart';
import 'package:planify/features/availability/presentation/controllers/availability_state.dart';

void main() {
  group('AvailabilityNotifier', () {
    const eventId = 'evt-1';
    late FakeAvailabilityRepository repository;
    late AvailabilityNotifier notifier;

    setUp(() async {
      repository = FakeAvailabilityRepository(
        delay: Duration.zero,
        initialAvailabilityByEvent: {
          eventId: [Slot(weekDay: 1, hourBlock: 9)],
        },
      );
      notifier = AvailabilityNotifier(repository: repository, eventId: eventId);
      await notifier.load();
    });

    tearDown(() => notifier.dispose());

    test('loads the saved slots for its event', () {
      expect(notifier.state.loadStatus, AvailabilityLoadStatus.success);
      expect(
        notifier.state.selectedSlots,
        unorderedEquals([Slot(weekDay: 1, hourBlock: 9)]),
      );
    });

    test('toggleSlot marks then unmarks a slot', () {
      final slot = Slot(weekDay: 2, hourBlock: 10);

      notifier.toggleSlot(slot);
      expect(notifier.state.selectedSlots, contains(slot));

      notifier.toggleSlot(slot);
      expect(notifier.state.selectedSlots, isNot(contains(slot)));
    });

    test('markSlot never removes a selected slot', () {
      final slot = Slot(weekDay: 1, hourBlock: 9);

      notifier.markSlot(slot);

      expect(notifier.state.selectedSlots, unorderedEquals([slot]));
    });

    test('save persists the complete current selection', () async {
      final newSlot = Slot(weekDay: 5, hourBlock: 18);
      notifier.markSlot(newSlot);

      await notifier.save();

      expect(notifier.state.saveStatus, AvailabilitySaveStatus.success);
      expect(
        await repository.load(eventId),
        unorderedEquals([Slot(weekDay: 1, hourBlock: 9), newSlot]),
      );
    });

    test('keeps the local selection when saving fails', () async {
      final selectedSlot = Slot(weekDay: 3, hourBlock: 14);
      final failingNotifier = AvailabilityNotifier(
        repository: _FailingAvailabilityRepository(),
        eventId: eventId,
      );
      await failingNotifier.load();
      failingNotifier.markSlot(selectedSlot);

      await failingNotifier.save();

      expect(failingNotifier.state.saveStatus, AvailabilitySaveStatus.error);
      expect(
        failingNotifier.state.selectedSlots,
        unorderedEquals([selectedSlot]),
      );
      failingNotifier.dispose();
    });
  });
}

class _FailingAvailabilityRepository implements AvailabilityRepository {
  @override
  Future<AvailabilityHeatmapDto> heatmap(String eventId) async {
    return AvailabilityHeatmapDto(totalParticipants: 0, slots: const []);
  }

  @override
  Future<List<Slot>> load(String eventId) async => [];

  @override
  Future<void> save(String eventId, List<Slot> slots) async {
    throw Exception('Unable to save availability');
  }
}
