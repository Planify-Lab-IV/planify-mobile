import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_colors.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/activity_log/data/fake_activity_log_repository.dart';
import 'package:planify/features/activity_log/domain/activity_entry.dart';
import 'package:planify/features/activity_log/domain/activity_log_repository.dart';
import 'package:planify/features/activity_log/presentation/controllers/activity_log_providers.dart';
import 'package:planify/features/activity_log/presentation/widgets/event_activity_card.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  Widget buildCard({
    required ActivityLogRepository repository,
    required String eventId,
  }) {
    return ProviderScope(
      overrides: [activityLogRepositoryProvider.overrideWithValue(repository)],
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
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventActivityCard(eventId: eventId),
          ),
        ),
      ),
    );
  }

  group('EventActivityCard', () {
    testWidgets('muestra las entradas con texto, icono y estilo por tipo', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCard(
          repository: FakeActivityLogRepository(delay: Duration.zero),
          eventId: 'evt-123',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_activity_card')), findsOneWidget);
      expect(
        find.byKey(const Key('event_activity_row_activity-evt-123-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('event_activity_row_activity-evt-123-5')),
        findsOneWidget,
      );
      expect(find.text('Ana creó la tarea Comprar carne'), findsOneWidget);
      expect(
        find.textContaining(r'Ana agregó el gasto Bebidas por $ 245,00'),
        findsOneWidget,
      );
      expect(find.text('Lucía hizo un cambio en el evento'), findsOneWidget);

      _expectIconStyle(
        tester,
        'activity-evt-123-1',
        Icons.event_available_outlined,
        AppColors.success,
      );
      _expectIconStyle(
        tester,
        'activity-evt-123-2',
        Icons.receipt_long_outlined,
        AppColors.danger,
      );
      _expectIconStyle(
        tester,
        'activity-evt-123-3',
        Icons.calendar_month_outlined,
        AppColors.primary,
      );
      _expectIconStyle(
        tester,
        'activity-evt-123-4',
        Icons.add_task_rounded,
        AppColors.warning,
      );
      _expectIconStyle(
        tester,
        'activity-evt-123-5',
        Icons.history_rounded,
        AppColors.onSurfaceVariant,
      );
    });

    testWidgets('preserva el orden entregado por el repositorio', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCard(
          repository: FakeActivityLogRepository(delay: Duration.zero),
          eventId: 'evt-123',
        ),
      );
      await tester.pumpAndSettle();

      final firstRow = tester.getTopLeft(
        find.byKey(const Key('event_activity_row_activity-evt-123-1')),
      );
      final lastRow = tester.getTopLeft(
        find.byKey(const Key('event_activity_row_activity-evt-123-5')),
      );

      expect(firstRow.dy, lessThan(lastRow.dy));
    });

    testWidgets('muestra el estado vacío', (tester) async {
      await tester.pumpWidget(
        buildCard(
          repository: FakeActivityLogRepository(delay: Duration.zero),
          eventId: 'evt-fake-demo',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_activity_empty')), findsOneWidget);
      expect(
        find.text('Sin actividad registrada en este evento.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra error y permite reintentar', (tester) async {
      final repository = FakeActivityLogRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      );
      await tester.pumpWidget(
        buildCard(repository: repository, eventId: 'evt-123'),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_activity_error')), findsOneWidget);
      expect(
        find.byKey(const Key('event_activity_retry_button')),
        findsOneWidget,
      );

      repository.shouldThrowError = false;
      await tester.tap(find.byKey(const Key('event_activity_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_activity_error')), findsNothing);
      expect(
        find.byKey(const Key('event_activity_row_activity-evt-123-1')),
        findsOneWidget,
      );
    });

    testWidgets('muestra loading mientras la respuesta sigue pendiente', (
      tester,
    ) async {
      final repository = _ControlledActivityLogRepository();
      await tester.pumpWidget(
        buildCard(repository: repository, eventId: 'evt-123'),
      );

      expect(find.byKey(const Key('event_activity_loading')), findsOneWidget);

      repository.complete(const <ActivityEntry>[]);
      await tester.pump();
      await tester.pump();
    });
  });
}

void _expectIconStyle(
  WidgetTester tester,
  String activityId,
  IconData iconData,
  Color color,
) {
  final icon = tester.widget<Icon>(
    find.descendant(
      of: find.byKey(Key('event_activity_icon_$activityId')),
      matching: find.byType(Icon),
    ),
  );

  expect(icon.icon, iconData);
  expect(icon.color, color);
}

class _ControlledActivityLogRepository implements ActivityLogRepository {
  final _completer = Completer<List<ActivityEntry>>();

  @override
  Future<List<ActivityEntry>> listEventActivity(String eventId) {
    return _completer.future;
  }

  void complete(List<ActivityEntry> entries) => _completer.complete(entries);
}
