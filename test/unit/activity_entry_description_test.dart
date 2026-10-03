import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:planify/features/activity_log/domain/activity_entry.dart';
import 'package:planify/features/activity_log/domain/activity_type.dart';
import 'package:planify/features/activity_log/presentation/activity_entry_description.dart';
import 'package:planify/l10n/app_localizations_en.dart';
import 'package:planify/l10n/app_localizations_es.dart';

void main() {
  final es = AppLocalizationsEs();

  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  ActivityEntry entry(ActivityType type, Map<String, dynamic> payload) {
    return ActivityEntry(
      id: 'activity-1',
      type: type,
      actorParticipantId: 'participant-1',
      actorUsername: 'Juli',
      payload: payload,
      createdAt: DateTime(2026, 1, 10, 20),
    );
  }

  group('activityEntryDescription', () {
    test('describe una tarea creada', () {
      final result = activityEntryDescription(
        entry(ActivityType.taskCreated, {'title': 'Comprar carne'}),
        es,
      );

      expect(result, 'Juli creó la tarea Comprar carne');
    });

    test('describe una actualización de disponibilidad', () {
      final result = activityEntryDescription(
        entry(ActivityType.availabilityUpdated, const {}),
        es,
      );

      expect(result, 'Juli actualizó su disponibilidad');
    });

    test('describe un gasto usando el formateador monetario', () {
      final result = activityEntryDescription(
        entry(ActivityType.expenseCreated, {
          'description': 'Bebidas',
          'totalAmountCents': 24500,
        }),
        es,
      );

      expect(result, r'Juli agregó el gasto Bebidas por $ 245,00');
    });

    test('describe un horario confirmado con fecha localizada', () {
      final result = activityEntryDescription(
        entry(ActivityType.scheduleConfirmed, {
          'startDateTime': DateTime(2026, 1, 10, 21),
        }),
        es,
      );

      expect(result, 'Juli confirmó el horario para 10/1/2026 21:00');
    });

    test('usa el texto genérico para un tipo desconocido', () {
      final result = activityEntryDescription(
        entry(ActivityType.unknown, {'sourceType': 'participantJoined'}),
        es,
      );

      expect(result, 'Juli hizo un cambio en el evento');
    });

    test('usa el texto genérico si falta un campo del payload', () {
      final result = activityEntryDescription(
        entry(ActivityType.taskCreated, {'title': null}),
        es,
      );

      expect(result, 'Juli hizo un cambio en el evento');
      expect(result, isNot(contains('null')));
    });

    test('usa el locale de las traducciones recibidas', () {
      final result = activityEntryDescription(
        entry(ActivityType.expenseCreated, {
          'description': 'Drinks',
          'totalAmountCents': 24500,
        }),
        AppLocalizationsEn(),
      );

      expect(result, r'Juli added the expense Drinks for $ 245.00');
    });
  });
}
