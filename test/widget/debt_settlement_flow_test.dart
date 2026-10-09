import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/data/fake_settlement_store.dart';
import 'package:planify/core/theme/app_colors.dart';
import 'package:planify/features/debts/data/fake_debts_repository.dart';
import 'package:planify/features/debts/domain/debt_settlement.dart';
import 'package:planify/features/debts/presentation/controllers/debts_providers.dart';
import 'package:planify/features/debts/presentation/widgets/event_debts_card.dart';
import 'package:planify/features/debts/presentation/widgets/settle_debt_dialog.dart';
import 'package:planify/features/balances/data/fake_balances_repository.dart';
import 'package:planify/features/balances/presentation/controllers/balances_providers.dart';
import 'package:planify/features/balances/presentation/widgets/person_balance_detail_sheet.dart';
import 'package:planify/features/balances/presentation/screens/balances_screen.dart';
import 'package:planify/features/events/domain/event_participant.dart';
import 'package:planify/l10n/app_localizations.dart';

const captureKey = Key('capture');
Widget app(
  Widget home, {
  FakeDebtsRepository? debts,
  FakeBalancesRepository? balances,
  String language = 'es',
}) => ProviderScope(
  overrides: [
    if (debts != null) debtsRepositoryProvider.overrideWithValue(debts),
    if (balances != null)
      balancesRepositoryProvider.overrideWithValue(balances),
  ],
  child: RepaintBoundary(
    key: captureKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
      ),
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  ),
);

Widget card({
  String eventId = 'evt-123',
  String eventName = 'Cumpleaños de Lucas',
  String? actor = 'participant-org-evt-123',
  List<EventParticipant> participants = const [],
}) => Scaffold(
  body: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: EventDebtsCard(
        eventId: eventId,
        eventName: eventName,
        currentParticipantId: actor,
        participants: participants,
      ),
    ),
  ),
);

Future<void> screenshot(WidgetTester tester, String name) async {
  // Opt-in evidence generation. These images are not platform-dependent CI goldens.
  if (!const bool.fromEnvironment('CAPTURE_SETTLEMENT')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('docs/evidence/PLANIFY-76').create(recursive: true);
    await File(
      'docs/evidence/PLANIFY-76/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_SETTLEMENT')) return;
    final sdk = Platform.environment['FLUTTER_ROOT'];
    if (sdk == null) {
      throw StateError('FLUTTER_ROOT is required for evidence fonts.');
    }
    for (final entry in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(
          File(
            '$sdk/bin/cache/artifacts/material_fonts/${entry.value}',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
    }
  });
  group('debt action', () {
    testWidgets(
      'a created event with two participants gets one settleable fake debt',
      (tester) async {
        final store = FakeSettlementStore();
        final debts = FakeDebtsRepository(
          delay: Duration.zero,
          store: store,
          initialEventDebts: const {},
        );
        const participants = [
          EventParticipant(
            id: 'participant-me',
            eventId: 'created-event',
            userId: 'user-me',
            username: 'Lucía',
            isAnonymous: false,
            isOrganizer: true,
          ),
          EventParticipant(
            id: 'participant-ana',
            eventId: 'created-event',
            userId: 'ana-created',
            username: 'Ana',
            isAnonymous: false,
            isOrganizer: false,
          ),
        ];

        await tester.pumpWidget(
          app(
            card(
              eventId: 'created-event',
              eventName: 'Evento creado',
              actor: 'participant-me',
              participants: participants,
            ),
            debts: debts,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const Key('event_debt_row_fixture-created-event-participant-me'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const Key(
              'settle_debt_button_fixture-created-event-participant-me',
            ),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Ana te debe'), findsOneWidget);
        expect(
          (await debts.listEventDebts('created-event')).debts,
          hasLength(1),
        );
      },
    );

    testWidgets('creating a fixture refreshes subscribed balances', (
      tester,
    ) async {
      final store = FakeSettlementStore();
      final balances = FakeBalancesRepository(
        delay: Duration.zero,
        store: store,
      );
      final debts = FakeDebtsRepository(
        delay: Duration.zero,
        store: store,
        initialEventDebts: const {},
      );
      var showFixture = false;

      await tester.pumpWidget(
        app(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final people = ref.watch(balancesNotifierProvider).people;
                      return Text(
                        '${people.length}:${people.map((person) => person.displayName).join(',')}',
                        key: const Key('fixture_balance_observer'),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () => setState(() => showFixture = true),
                    child: const Text('Prepare fixture'),
                  ),
                  if (showFixture)
                    Expanded(
                      child: EventDebtsCard(
                        eventId: 'created-event',
                        eventName: 'Evento creado',
                        currentParticipantId: 'participant-me',
                        participants: const [
                          EventParticipant(
                            id: 'participant-me',
                            eventId: 'created-event',
                            userId: 'user-me',
                            username: 'Lucía',
                            isAnonymous: false,
                            isOrganizer: true,
                          ),
                          EventParticipant(
                            id: 'participant-renata',
                            eventId: 'created-event',
                            userId: 'renata-created',
                            username: 'Renata',
                            isAnonymous: false,
                            isOrganizer: false,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          debts: debts,
          balances: balances,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3:Ana,Martín,Sol'), findsOneWidget);

      await tester.tap(find.text('Prepare fixture'));
      await tester.pumpAndSettle();

      expect(find.text('4:Ana,Martín,Sol,Renata'), findsOneWidget);
    });

    testWidgets('an event with one participant keeps the empty state', (
      tester,
    ) async {
      final debts = FakeDebtsRepository(
        delay: Duration.zero,
        initialEventDebts: const {},
      );
      await tester.pumpWidget(
        app(
          card(
            eventId: 'solo-event',
            eventName: 'Evento individual',
            actor: 'participant-me',
            participants: const [
              EventParticipant(
                id: 'participant-me',
                eventId: 'solo-event',
                userId: 'user-me',
                username: 'Lucía',
                isAnonymous: false,
                isOrganizer: true,
              ),
            ],
          ),
          debts: debts,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_debts_empty')), findsOneWidget);
      expect((await debts.listEventDebts('solo-event')).debts, isEmpty);
    });

    for (final actor in <String?>[
      'participant-org-evt-123',
      'participant-member-evt-123',
      'participant-anon-evt-123',
      'other',
      null,
    ]) {
      testWidgets('visibility for $actor', (tester) async {
        await tester.pumpWidget(
          app(
            card(actor: actor),
            debts: FakeDebtsRepository(delay: Duration.zero),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('settle_debt_button_debt-evt-123-1')),
          actor == 'participant-org-evt-123' ||
                  actor == 'participant-member-evt-123'
              ? findsOneWidget
              : findsNothing,
        );
        expect(
          find.byKey(const Key('settle_debt_button_debt-evt-123-3')),
          findsNothing,
        );
      });
    }

    testWidgets('personalizes row and dialog for both debt directions', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          card(actor: 'participant-org-evt-123'),
          debts: FakeDebtsRepository(delay: Duration.zero),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ana te debe \$ 500,00'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('settle_debt_button_debt-evt-123-1')),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('la deuda de Ana por \$ 500,00'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('settle_debt_dialog_dismiss_button')),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        app(
          card(actor: 'participant-member-evt-123'),
          debts: FakeDebtsRepository(delay: Duration.zero),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Le debés \$ 500,00 a Lucía'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('settle_debt_button_debt-evt-123-1')),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('tu deuda con Lucía por \$ 500,00'),
        findsOneWidget,
      );
    });

    testWidgets('uses the task-style left hierarchy and status presentation', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          card(actor: 'participant-org-evt-123'),
          debts: FakeDebtsRepository(delay: Duration.zero),
        ),
      );
      await tester.pumpAndSettle();

      final pendingIcon = tester.widget<Icon>(
        find.byKey(const Key('event_debt_status_icon_debt-evt-123-1')),
      );
      expect(pendingIcon.icon, Icons.schedule_rounded);
      expect(pendingIcon.color, AppColors.warning);

      final settledIcon = tester.widget<Icon>(
        find.byKey(const Key('event_debt_status_icon_debt-evt-123-3')),
      );
      expect(settledIcon.icon, Icons.check_circle_rounded);
      expect(settledIcon.color, AppColors.success);

      final description = find.byKey(
        const Key('event_debt_description_debt-evt-123-1'),
      );
      final status = find.byKey(const Key('event_debt_status_debt-evt-123-1'));
      final action = find.byKey(const Key('settle_debt_button_debt-evt-123-1'));
      final descriptionX = tester.getTopLeft(description).dx;
      expect(tester.getTopLeft(status).dx, closeTo(descriptionX, 0.1));
      expect(tester.getTopLeft(action).dx, closeTo(descriptionX, 0.1));
      expect(
        tester
            .getTopLeft(
              find.byKey(const Key('event_debt_status_icon_debt-evt-123-1')),
            )
            .dx,
        lessThan(descriptionX),
      );

      final button = tester.widget<FilledButton>(action);
      final context = tester.element(action);
      final style = button.style ?? button.defaultStyleOf(context);
      expect(style.backgroundColor?.resolve({}), AppColors.primary);
      expect(style.foregroundColor?.resolve({}), Colors.white);
      expect(
        find.byKey(const Key('settle_debt_button_debt-evt-123-3')),
        findsNothing,
      );
    });

    testWidgets(
      'cancel does not call repository; confirm updates row without spinner',
      (tester) async {
        final debts = FakeDebtsRepository(delay: Duration.zero);
        await tester.pumpWidget(app(card(), debts: debts));
        await tester.pumpAndSettle();
        final action = find.byKey(
          const Key('settle_debt_button_debt-evt-123-1'),
        );
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.textContaining('Ana por \$ 500,00'), findsOneWidget);
        expect(find.textContaining('Cumpleaños de Lucas'), findsOneWidget);
        final confirm = tester.widget<ElevatedButton>(
          find.byKey(const Key('settle_debt_dialog_confirm_button')),
        );
        expect(confirm.style!.backgroundColor!.resolve({}), AppColors.error);
        await screenshot(tester, '01-confirmacion-puntual');
        await tester.tap(
          find.byKey(const Key('settle_debt_dialog_dismiss_button')),
        );
        await tester.pumpAndSettle();
        expect(debts.settlementCalls, 0);
        await tester.tap(action);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('settle_debt_dialog_confirm_button')),
        );
        await tester.pumpAndSettle();
        expect(debts.settlementCalls, 1);
        expect(action, findsNothing);
        expect(find.byKey(const Key('event_debts_loading')), findsNothing);
        expect(find.text('Saldada'), findsNWidgets(2));
        await screenshot(tester, '02-resultado-puntual');
      },
    );

    testWidgets(
      'double taps open one dialog and disable action while submitting',
      (tester) async {
        final debts = _DelayedSettlementRepository();
        await tester.pumpWidget(app(card(), debts: debts));
        await tester.pumpAndSettle();
        final action = find.byKey(
          const Key('settle_debt_button_debt-evt-123-1'),
        );
        final onPressed = tester.widget<FilledButton>(action).onPressed!;
        onPressed();
        onPressed();
        await tester.pumpAndSettle();
        expect(find.byType(SettleDebtDialog), findsOneWidget);
        await tester.tap(
          find.byKey(const Key('settle_debt_dialog_confirm_button')),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.widget<FilledButton>(action).onPressed, isNull);
        debts.gate.complete();
        await tester.pumpAndSettle();
        expect(debts.settlementCalls, 1);
      },
    );

    testWidgets('409 refreshes row without error', (tester) async {
      final debts = FakeDebtsRepository(delay: Duration.zero);
      await tester.pumpWidget(app(card(), debts: debts));
      await tester.pumpAndSettle();
      await debts.settleDebt('evt-123', 'debt-evt-123-1');
      await tester.tap(
        find.byKey(const Key('settle_debt_button_debt-evt-123-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('settle_debt_dialog_confirm_button')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settle_error_snackbar')), findsNothing);
      expect(
        find.byKey(const Key('settle_debt_button_debt-evt-123-1')),
        findsNothing,
      );
    });

    for (final error in <DebtException>[
      const DebtAuthorizationException(),
      const DebtNotFoundException(),
      const DebtNetworkException(),
    ]) {
      testWidgets(
        '${error.runtimeType} keeps the row and exposes appropriate feedback',
        (tester) async {
          final debts = FakeDebtsRepository(
            delay: Duration.zero,
            settlementError: error,
          );
          await tester.pumpWidget(app(card(), debts: debts));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const Key('settle_debt_button_debt-evt-123-1')),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const Key('settle_debt_dialog_confirm_button')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('settle_error_snackbar')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('event_debt_row_debt-evt-123-1')),
            findsOneWidget,
          );
          expect(
            find.text('Reintentar'),
            error is DebtNetworkException ? findsOneWidget : findsNothing,
          );
          if (error is DebtNetworkException) {
            debts.settlementError = null;
            await tester.tap(find.text('Reintentar'));
            await tester.pumpAndSettle();
            expect(find.byType(SettleDebtDialog), findsOneWidget);
            await tester.tap(
              find.byKey(const Key('settle_debt_dialog_confirm_button')),
            );
            await tester.pumpAndSettle();
            expect(
              find.byKey(const Key('settle_debt_button_debt-evt-123-1')),
              findsNothing,
            );
          }
        },
      );
    }
  });

  group('settle all', () {
    Future<({FakeDebtsRepository debts, FakeBalancesRepository balances})> open(
      WidgetTester tester, {
      String person = 'user:ana',
      DebtException? error,
    }) async {
      final store = FakeSettlementStore();
      final balances = FakeBalancesRepository(
        delay: Duration.zero,
        store: store,
      );
      final debts = FakeDebtsRepository(
        delay: Duration.zero,
        store: store,
        settlementError: error,
      );
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => PersonBalanceDetailSheet.show(context, person),
                child: const Text('Open'),
              ),
            ),
          ),
          debts: debts,
          balances: balances,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return (debts: debts, balances: balances);
    }

    testWidgets('settled person has no action', (tester) async {
      await open(tester, person: 'user:sol');
      expect(find.byKey(const Key('settle_all_button')), findsNothing);
    });

    testWidgets(
      'warns about all events; cancel preserves debts; success closes sheet',
      (tester) async {
        final repos = await open(tester);
        await tester.tap(find.byKey(const Key('settle_all_button')));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('todos los eventos en común'),
          findsOneWidget,
        );
        expect(find.textContaining('no se puede deshacer'), findsOneWidget);
        await screenshot(tester, '03-confirmacion-saldar-todo');
        await tester.tap(
          find.byKey(const Key('settle_all_dialog_dismiss_button')),
        );
        await tester.pumpAndSettle();
        expect(repos.debts.settlementCalls, 0);
        await tester.tap(find.byKey(const Key('settle_all_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('settle_all_dialog_confirm_button')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PersonBalanceDetailSheet), findsNothing);
        expect(
          (await repos.balances.getPersonDetail('user:ana')).status.isSettled,
          isTrue,
        );
      },
    );

    testWidgets(
      'global screen reflects new balance and keeps selected filter',
      (tester) async {
        final store = FakeSettlementStore();
        final balances = FakeBalancesRepository(
          delay: Duration.zero,
          store: store,
        );
        final debts = FakeDebtsRepository(delay: Duration.zero, store: store);
        await tester.pumpWidget(
          app(const BalancesScreen(), debts: debts, balances: balances),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('balance_filter_i_owe')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ana'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('settle_all_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('settle_all_dialog_confirm_button')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PersonBalanceDetailSheet), findsNothing);
        expect(find.byKey(const Key('balances_filter_empty')), findsOneWidget);
        expect(find.byKey(const Key('balances_loading')), findsNothing);
        await tester.tap(find.byKey(const Key('balance_filter_all')));
        await tester.pumpAndSettle();
        expect(find.text('Saldado'), findsNWidgets(2));
        await screenshot(tester, '04-resultado-balances');
      },
    );

    for (final error in <DebtException>[
      const DebtAuthorizationException(),
      const DebtNotFoundException(),
      const DebtNetworkException(),
      const DebtAlreadySettledException(),
    ]) {
      testWidgets('${error.runtimeType} keeps sheet when not settled', (
        tester,
      ) async {
        await open(tester, error: error);
        await tester.tap(find.byKey(const Key('settle_all_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('settle_all_dialog_confirm_button')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PersonBalanceDetailSheet), findsOneWidget);
        expect(
          find.byKey(const Key('person_balance_detail_loading')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('settle_error_snackbar')),
          error is DebtAlreadySettledException ? findsNothing : findsOneWidget,
        );
      });
    }

    testWidgets('network errors expose a tappable Retry above the sheet', (
      tester,
    ) async {
      final repos = await open(tester, error: const DebtNetworkException());
      await tester.tap(find.byKey(const Key('settle_all_button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('settle_all_dialog_confirm_button')),
      );
      await tester.pumpAndSettle();

      final retry = find.text('Reintentar').hitTestable();
      expect(retry, findsOneWidget);

      repos.debts.settlementError = null;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('settle_all_dialog_confirm_button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('settle_all_dialog_confirm_button')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PersonBalanceDetailSheet), findsNothing);
    });
  });

  testWidgets('both confirmations have English messages and return bool', (
    tester,
  ) async {
    bool? answer;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () async {
                    answer = await SettleDebtDialog.show(
                      context,
                      personName: 'Ana',
                      amount: '\$ 500.00',
                      eventName: 'Birthday',
                      direction: SettleDebtDirection.iOwe,
                    );
                  },
                  child: const Text('Single'),
                ),
                TextButton(
                  onPressed: () async {
                    answer = await SettleDebtDialog.show(
                      context,
                      personName: 'Ana',
                    );
                  },
                  child: const Text('All'),
                ),
              ],
            ),
          ),
        ),
        language: 'en',
      ),
    );
    await tester.tap(find.text('Single'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Birthday'), findsOneWidget);
    expect(find.textContaining('your debt with Ana'), findsOneWidget);
    expect(find.textContaining('cannot be undone'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('settle_debt_dialog_confirm_button')),
    );
    await tester.pumpAndSettle();
    expect(answer, isTrue);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.textContaining('all events you share'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settle_all_dialog_dismiss_button')));
    await tester.pumpAndSettle();
    expect(answer, isFalse);
  });
}

class _DelayedSettlementRepository extends FakeDebtsRepository {
  final gate = Completer<void>();
  _DelayedSettlementRepository() : super(delay: Duration.zero);
  @override
  Future<void> settleDebt(String eventId, String debtId) async {
    await gate.future;
    await super.settleDebt(eventId, debtId);
  }
}
