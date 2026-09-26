import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/debts/data/fake_debts_repository.dart';
import 'package:planify/features/debts/domain/debts_repository.dart';
import 'package:planify/features/debts/domain/event_debts.dart';
import 'package:planify/features/debts/presentation/controllers/event_debts_notifier.dart';
import 'package:planify/features/debts/presentation/controllers/event_debts_state.dart';

void main() {
  group('EventDebtsNotifier', () {
    test('carga las deudas del evento al crearse', () async {
      final notifier = EventDebtsNotifier(
        repository: FakeDebtsRepository(delay: Duration.zero),
        eventId: 'evt-123',
      );

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.loadStatus, EventDebtsLoadStatus.success);
      expect(notifier.state.eventDebts.debts, hasLength(3));
      notifier.dispose();
    });

    test('expone error controlado si el repositorio falla', () async {
      final notifier = EventDebtsNotifier(
        repository: FakeDebtsRepository(
          delay: Duration.zero,
          shouldThrowError: true,
        ),
        eventId: 'evt-123',
      );

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.loadStatus, EventDebtsLoadStatus.error);
      expect(notifier.state.eventDebts.debts, isEmpty);
      notifier.dispose();
    });

    test('reload vuelve a consultar el repositorio', () async {
      final repository = _CountingDebtsRepository();
      final notifier = EventDebtsNotifier(
        repository: repository,
        eventId: 'evt-123',
      );

      await Future<void>.delayed(Duration.zero);
      await notifier.reload();

      expect(repository.callCount, 2);
      expect(notifier.state.loadStatus, EventDebtsLoadStatus.success);
      notifier.dispose();
    });
  });
}

class _CountingDebtsRepository implements DebtsRepository {
  int callCount = 0;

  @override
  Future<EventDebts> listEventDebts(String eventId) async {
    callCount++;
    return const EventDebts(debts: [], allSettled: false);
  }
}
