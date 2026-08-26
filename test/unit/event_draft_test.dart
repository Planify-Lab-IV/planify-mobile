import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/domain/event_draft.dart';
import 'package:planify/features/events/presentation/controllers/event_draft_notifier.dart';

void main() {
  group('EventDraft Domain Model', () {
    test('default constructor creates empty draft', () {
      const draft = EventDraft();
      expect(draft.name, isEmpty);
      expect(draft.location, isEmpty);
      expect(draft.isEmpty, isTrue);
      expect(draft.isStep1Valid, isFalse);
    });

    test('empty named constructor creates empty draft', () {
      const draft = EventDraft.empty();
      expect(draft.isEmpty, isTrue);
      expect(draft.isStep1Valid, isFalse);
    });

    test(
      'isStep1Valid returns true only when name and location are not blank',
      () {
        expect(const EventDraft(name: '', location: '').isStep1Valid, isFalse);
        expect(
          const EventDraft(name: 'Fiesta', location: '').isStep1Valid,
          isFalse,
        );
        expect(
          const EventDraft(name: '', location: 'Casa').isStep1Valid,
          isFalse,
        );
        expect(
          const EventDraft(name: '   ', location: 'Casa').isStep1Valid,
          isFalse,
        );
        expect(
          const EventDraft(name: 'Fiesta', location: '   ').isStep1Valid,
          isFalse,
        );
        expect(
          const EventDraft(
            name: 'Fiesta',
            location: 'Casa de Lucas',
          ).isStep1Valid,
          isTrue,
        );
      },
    );

    test('copyWith copies and overrides fields correctly', () {
      const draft = EventDraft(name: 'Asado', location: 'Club');
      final updated = draft.copyWith(location: 'Parque');

      expect(updated.name, equals('Asado'));
      expect(updated.location, equals('Parque'));

      final updatedName = draft.copyWith(name: 'Fiesta');
      expect(updatedName.name, equals('Fiesta'));
      expect(updatedName.location, equals('Club'));
    });

    test('equality and hashCode work as expected', () {
      const draft1 = EventDraft(name: 'Concierto', location: 'Estadio');
      const draft2 = EventDraft(name: 'Concierto', location: 'Estadio');
      const draft3 = EventDraft(name: 'Cena', location: 'Restaurante');

      expect(draft1, equals(draft2));
      expect(draft1.hashCode, equals(draft2.hashCode));
      expect(draft1, isNot(equals(draft3)));
    });

    test('toString returns descriptive string', () {
      const draft = EventDraft(name: 'Reunión', location: 'Oficina');
      expect(draft.toString(), contains('Reunión'));
      expect(draft.toString(), contains('Oficina'));
    });
  });

  group('EventDraftNotifier', () {
    late EventDraftNotifier notifier;

    setUp(() {
      notifier = EventDraftNotifier();
    });

    test('estado inicial es un borrador vacío', () {
      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.name, isEmpty);
      expect(notifier.state.location, isEmpty);
    });

    test(
      'updateBasicInfo actualiza nombre y lugar con strings limpios (trim)',
      () {
        notifier.updateBasicInfo(
          name: '  Cumpleaños de Lucas  ',
          location: '  Av. Corrientes 1234  ',
        );

        expect(notifier.state.name, equals('Cumpleaños de Lucas'));
        expect(notifier.state.location, equals('Av. Corrientes 1234'));
        expect(notifier.state.isStep1Valid, isTrue);
      },
    );

    test('updateName actualiza solo el nombre', () {
      notifier.updateBasicInfo(name: 'Original', location: 'Lugar');
      notifier.updateName('  Nombre Modificado  ');

      expect(notifier.state.name, equals('Nombre Modificado'));
      expect(notifier.state.location, equals('Lugar'));
    });

    test('updateLocation actualiza solo el lugar', () {
      notifier.updateBasicInfo(name: 'Original', location: 'Lugar');
      notifier.updateLocation('  Lugar Modificado  ');

      expect(notifier.state.name, equals('Original'));
      expect(notifier.state.location, equals('Lugar Modificado'));
    });

    test('reset restablece el borrador al estado vacío', () {
      notifier.updateBasicInfo(name: 'Evento a borrar', location: 'Ubicacion');
      expect(notifier.state.isEmpty, isFalse);

      notifier.reset();
      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.name, isEmpty);
      expect(notifier.state.location, isEmpty);
    });
  });
}
