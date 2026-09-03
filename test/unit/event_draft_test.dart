import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/domain/event_draft.dart';
import 'package:planify/features/events/creation/controllers/event_draft_notifier.dart';

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

    test('isStep2Valid valida correctamente segun modo nuevo o existente', () {
      // Modo grupo existente
      expect(
        const EventDraft(isNewGroup: false, selectedGroupId: null).isStep2Valid,
        isFalse,
      );
      expect(
        const EventDraft(
          isNewGroup: false,
          selectedGroupId: 'grp-1',
        ).isStep2Valid,
        isTrue,
      );

      // Modo grupo nuevo
      expect(
        const EventDraft(isNewGroup: true, newGroupName: null).isStep2Valid,
        isFalse,
      );
      expect(
        const EventDraft(isNewGroup: true, newGroupName: '   ').isStep2Valid,
        isFalse,
      );
      expect(
        const EventDraft(isNewGroup: true, newGroupName: 'Amigos').isStep2Valid,
        isTrue,
      );
    });

    test('isValid requiere paso 1 y paso 2 validos', () {
      expect(
        const EventDraft(
          name: 'Asado',
          location: 'Club',
          isNewGroup: false,
          selectedGroupId: 'grp-1',
        ).isValid,
        isTrue,
      );

      expect(
        const EventDraft(
          name: 'Asado',
          location: 'Club',
          isNewGroup: false,
          selectedGroupId: null,
        ).isValid,
        isFalse,
      );
    });

    test('reset restablece el borrador al estado vacío', () {
      notifier.updateBasicInfo(name: 'Evento a borrar', location: 'Ubicacion');
      notifier.setSelectedGroup(groupId: 'grp-1', groupName: 'Amigos');
      notifier.addMember('test@email.com');
      expect(notifier.state.isEmpty, isFalse);

      notifier.reset();
      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.name, isEmpty);
      expect(notifier.state.location, isEmpty);
      expect(notifier.state.selectedGroupId, isNull);
      expect(notifier.state.newGroupMembers, isEmpty);
    });

    test('setIsNewGroup cambia el modo', () {
      notifier.setIsNewGroup(true);
      expect(notifier.state.isNewGroup, isTrue);

      notifier.setIsNewGroup(false);
      expect(notifier.state.isNewGroup, isFalse);
    });

    test('setSelectedGroup asigna id y nombre y desactiva isNewGroup', () {
      notifier.setIsNewGroup(true);
      notifier.setSelectedGroup(groupId: 'grp-10', groupName: 'Familia');

      expect(notifier.state.selectedGroupId, equals('grp-10'));
      expect(notifier.state.selectedGroupName, equals('Familia'));
      expect(notifier.state.isNewGroup, isFalse);
    });

    test('setNewGroupName asigna nombre de nuevo grupo con trim', () {
      notifier.setNewGroupName('  Compañeros de la Facultad  ');
      expect(notifier.state.newGroupName, equals('Compañeros de la Facultad'));
    });

    test(
      'addMember y removeMember gestionan identificadores sin duplicados',
      () {
        notifier.addMember('  lucas@planify.com  ');
        notifier.addMember('lucas@planify.com'); // Duplicado no debe agregarse
        notifier.addMember('@juanperez');

        expect(notifier.state.newGroupMembers.length, equals(2));
        expect(
          notifier.state.newGroupMembers,
          containsAll(['lucas@planify.com', '@juanperez']),
        );

        notifier.removeMember('lucas@planify.com');
        expect(notifier.state.newGroupMembers.length, equals(1));
        expect(notifier.state.newGroupMembers, contains('@juanperez'));
      },
    );
  });
}
