import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/core/theme/app_colors.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/data/dio_client.dart';
import 'package:planify/features/activity_log/presentation/widgets/event_activity_card.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  Widget buildCard(Dio dio) => ProviderScope(
    // Exercise the production repository provider, notifier and card together.
    overrides: [dioClientProvider.overrideWithValue(dio)],
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
        body: SingleChildScrollView(child: EventActivityCard(eventId: 'evt-1')),
      ),
    ),
  );

  Map<String, dynamic> backendEntry(
    String id,
    String type,
    String createdAt,
    Map<String, dynamic> payload,
  ) => {
    'id': id,
    'type': type,
    'actor': {'participantId': 'participant-dev1', 'username': 'dev1'},
    'createdAt': createdAt,
    'payload': payload,
  };

  Map<String, dynamic> activityResponse() => {
    'entries': [
      backendEntry(
        'schedule-1',
        'schedule_confirmed',
        '2026-10-13T18:00:00.000Z',
        {'startDateTime': '2026-10-20T21:00:00.000Z'},
      ),
      backendEntry('expense-1', 'expense_created', '2026-10-13T17:00:00.000Z', {
        'expenseId': 'expense-1',
        'description': 'Bebidas',
        'totalAmountCents': 24500,
      }),
      backendEntry(
        'availability-1',
        'availability_updated',
        '2026-10-13T16:00:00.000Z',
        {'slotCount': 3},
      ),
      backendEntry('task-1', 'task_created', '2026-10-13T15:00:00.000Z', {
        'taskId': 'task-1',
        'title': 'Comprar bebidas',
      }),
    ],
  };

  Dio respondingWith(dynamic body) {
    final dio = Dio();
    addTearDown(() => dio.close(force: true));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: body,
          ),
        ),
      ),
    );
    return dio;
  }

  group('EventActivityCard with the HTTP repository', () {
    for (final viewer in ['dev1', 'dev2']) {
      testWidgets('renders the same backend feed for viewer $viewer', (
        tester,
      ) async {
        final dio = DioClient.create(bearerToken: 'test-token-$viewer');
        addTearDown(() => dio.close(force: true));
        RequestOptions? request;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              request = options;
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: activityResponse(),
                ),
              );
            },
          ),
        );

        await tester.pumpWidget(buildCard(dio));
        await tester.pumpAndSettle();

        expect(request?.method, 'GET');
        expect(request?.path, '/events/evt-1/activity-log');
        expect(request?.headers['Authorization'], 'Bearer test-token-$viewer');
        expect(find.text('dev1 creó la tarea Comprar bebidas'), findsOneWidget);
        expect(find.text('dev1 actualizó su disponibilidad'), findsOneWidget);
        expect(
          find.text(r'dev1 agregó el gasto Bebidas por $ 245,00'),
          findsOneWidget,
        );
        final schedule = DateFormat.yMd(
          'es',
        ).add_Hm().format(DateTime.parse('2026-10-20T21:00:00.000Z').toLocal());
        expect(
          find.text('dev1 confirmó el horario para $schedule'),
          findsOneWidget,
        );

        final ids = ['schedule-1', 'expense-1', 'availability-1', 'task-1'];
        final icons = [
          Icons.event_available_outlined,
          Icons.receipt_long_outlined,
          Icons.calendar_month_outlined,
          Icons.add_task_rounded,
        ];
        final colors = [
          AppColors.success,
          AppColors.danger,
          AppColors.primary,
          AppColors.warning,
        ];
        for (var index = 0; index < ids.length; index++) {
          final row = find.byKey(Key('event_activity_row_${ids[index]}'));
          expect(row, findsOneWidget);
          final icon = tester.widget<Icon>(
            find.descendant(
              of: find.byKey(Key('event_activity_icon_${ids[index]}')),
              matching: find.byType(Icon),
            ),
          );
          expect(icon.icon, icons[index]);
          expect(icon.color, colors[index]);
          if (index > 0) {
            expect(
              tester.getTopLeft(row).dy,
              greaterThan(
                tester
                    .getTopLeft(
                      find.byKey(Key('event_activity_row_${ids[index - 1]}')),
                    )
                    .dy,
              ),
            );
          }
        }
      });
    }

    testWidgets('renders an empty backend response as the empty state', (
      tester,
    ) async {
      await tester.pumpWidget(buildCard(respondingWith({'entries': []})));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('event_activity_empty')), findsOneWidget);
      expect(
        find.text('Sin actividad registrada en este evento.'),
        findsOneWidget,
      );
    });

    testWidgets('recovers from a network error when retry is tapped', (
      tester,
    ) async {
      var shouldFail = true;
      var requests = 0;
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests++;
            if (shouldFail) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                ),
              );
            } else {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: activityResponse(),
                ),
              );
            }
          },
        ),
      );
      await tester.pumpWidget(buildCard(dio));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('event_activity_error')), findsOneWidget);
      expect(requests, 1);

      shouldFail = false;
      await tester.tap(find.byKey(const Key('event_activity_retry_button')));
      await tester.pumpAndSettle();

      expect(requests, 2);
      expect(find.byKey(const Key('event_activity_error')), findsNothing);
      expect(find.text('dev1 creó la tarea Comprar bebidas'), findsOneWidget);
    });

    testWidgets(
      'renders malformed data as an error instead of a partial feed',
      (tester) async {
        final body = activityResponse();
        (body['entries'] as List).add({'id': 'incomplete'});
        await tester.pumpWidget(buildCard(respondingWith(body)));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('event_activity_error')), findsOneWidget);
        expect(find.text('dev1 creó la tarea Comprar bebidas'), findsNothing);
      },
    );
  });
}
