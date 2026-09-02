import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/domain/event.dart';
import 'package:planify/features/events/domain/event_status.dart';

void main() {
  group('Event Domain Model Tests', () {
    const testEvent = Event(
      id: 'evt-001',
      name: 'Asado Fin de Año',
      location: 'Parque Sarmiento',
      organizerId: 'usr-org-1',
      status: EventStatus.active,
    );

    test('inicializa con valores correctos y estado active por defecto', () {
      const defaultEvent = Event(
        id: 'evt-002',
        name: 'Reunión de Equipo',
        location: 'Oficina Central',
        organizerId: 'usr-org-2',
      );

      expect(defaultEvent.id, 'evt-002');
      expect(defaultEvent.name, 'Reunión de Equipo');
      expect(defaultEvent.location, 'Oficina Central');
      expect(defaultEvent.organizerId, 'usr-org-2');
      expect(defaultEvent.status, EventStatus.active);
      expect(defaultEvent.isActive, isTrue);
      expect(defaultEvent.isCancelled, isFalse);
    });

    test('isCancelled e isActive reflejan el estado correctamente', () {
      expect(testEvent.isActive, isTrue);
      expect(testEvent.isCancelled, isFalse);

      final cancelledEvent = testEvent.copyWith(status: EventStatus.cancelled);
      expect(cancelledEvent.isActive, isFalse);
      expect(cancelledEvent.isCancelled, isTrue);
    });

    test('copyWith preserva campos existentes cuando no se especifican', () {
      final updated = testEvent.copyWith(name: 'Asado de Primavera');

      expect(updated.id, testEvent.id);
      expect(updated.name, 'Asado de Primavera');
      expect(updated.location, testEvent.location);
      expect(updated.organizerId, testEvent.organizerId);
      expect(updated.status, testEvent.status);
    });

    test('copyWith sobreescribe todos los campos cuando se proveen', () {
      final updated = testEvent.copyWith(
        id: 'evt-999',
        name: 'Nuevo Nombre',
        location: 'Nueva Ubicación',
        organizerId: 'usr-999',
        status: EventStatus.cancelled,
      );

      expect(updated.id, 'evt-999');
      expect(updated.name, 'Nuevo Nombre');
      expect(updated.location, 'Nueva Ubicación');
      expect(updated.organizerId, 'usr-999');
      expect(updated.status, EventStatus.cancelled);
    });

    test('igualdad estructural por valor (==) y hashCode', () {
      const event1 = Event(
        id: 'evt-001',
        name: 'Asado Fin de Año',
        location: 'Parque Sarmiento',
        organizerId: 'usr-org-1',
        status: EventStatus.active,
      );

      const event2 = Event(
        id: 'evt-001',
        name: 'Asado Fin de Año',
        location: 'Parque Sarmiento',
        organizerId: 'usr-org-1',
        status: EventStatus.active,
      );

      const differentEvent = Event(
        id: 'evt-002',
        name: 'Asado Fin de Año',
        location: 'Parque Sarmiento',
        organizerId: 'usr-org-1',
        status: EventStatus.active,
      );

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
      expect(event1, isNot(equals(differentEvent)));
    });

    test('toString retorna formato legible con propiedades', () {
      final str = testEvent.toString();
      expect(str, contains('evt-001'));
      expect(str, contains('Asado Fin de Año'));
      expect(str, contains('Parque Sarmiento'));
      expect(str, contains('usr-org-1'));
      expect(str, contains('EventStatus.active'));
    });
  });
}
