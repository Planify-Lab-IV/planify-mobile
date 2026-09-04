import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/detail/controllers/events_providers.dart';
import 'package:planify/features/events/attendance/widgets/attendance_response_selector.dart';
import 'package:planify/features/events/domain/attendance_status.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  const eventId = 'evt-123';
  const participantId = 'anon-456';

  Widget buildSelector(FakeEventsRepository repository) {
    return ProviderScope(
      overrides: [eventsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: const Scaffold(
          body: AttendanceResponseSelector(
            eventId: eventId,
            participantId: participantId,
          ),
        ),
      ),
    );
  }

  group('AttendanceResponseSelector', () {
    testWidgets('confirma asistencia y muestra el estado confirmado', (
      tester,
    ) async {
      final repository = FakeEventsRepository(delay: Duration.zero);

      await tester.pumpWidget(buildSelector(repository));
      await tester.pump();
      await tester.pump();

      expect(find.text('Sin respuesta'), findsOneWidget);
      await tester.tap(find.byKey(const Key('attendance_confirm_button')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.byKey(const Key('attendance_reject_button')), findsOneWidget);
      expect(
        await repository.getAttendance(eventId, participantId),
        AttendanceStatus.confirmed,
      );
    });

    testWidgets('rechaza asistencia y permite cambiar de opinión', (
      tester,
    ) async {
      final repository = FakeEventsRepository(delay: Duration.zero);
      await repository.confirmAssistance(
        eventId,
        participantId,
        AttendanceStatus.confirmed.name,
      );

      await tester.pumpWidget(buildSelector(repository));
      await tester.pump();
      await tester.pump();

      expect(find.text('Confirmado'), findsOneWidget);
      await tester.tap(find.byKey(const Key('attendance_reject_button')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Rechazado'), findsOneWidget);
      expect(
        await repository.getAttendance(eventId, participantId),
        AttendanceStatus.rejected,
      );
    });

    testWidgets('revierte la selección y comunica el error si falla la fake', (
      tester,
    ) async {
      final repository = FakeEventsRepository(delay: Duration.zero);
      await repository.confirmAssistance(
        eventId,
        participantId,
        AttendanceStatus.confirmed.name,
      );
      repository.shouldFailAttendanceResponse = true;

      await tester.pumpWidget(buildSelector(repository));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('attendance_reject_button')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.byKey(const Key('attendance_error_message')), findsOneWidget);
      expect(
        await repository.getAttendance(eventId, participantId),
        AttendanceStatus.confirmed,
      );
    });
  });
}
