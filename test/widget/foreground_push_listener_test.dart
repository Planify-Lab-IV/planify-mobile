import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/core/services/push_messaging_service.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/activity_log/domain/unread_counts.dart';
import 'package:planify/features/activity_log/presentation/controllers/activity_log_providers.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/auth/presentation/controllers/auth_state.dart';
import 'package:planify/features/events/data/events_repository_provider.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/detail/screens/event_detail_screen.dart';
import 'package:planify/features/expenses/data/fake_expenses_repository.dart';
import 'package:planify/features/expenses/presentation/controllers/expenses_providers.dart';
import 'package:planify/features/notifications/data/fake_notifications_repository.dart';
import 'package:planify/features/notifications/presentation/widgets/foreground_push_listener.dart';
import 'package:planify/features/notifications/presentation/widgets/opened_push_listener.dart';
import 'package:planify/l10n/app_localizations.dart';

import '../helpers/fake_push_messaging_service.dart';

const _organizer = OrganizerSession(
  userId: 'organizer-1',
  email: 'user@example.com',
  name: 'Usuario',
  username: 'usuario',
  token: 'session-token',
);
const _anonymous = AnonymousSession(
  participantId: 'participant-1',
  name: 'Invitado',
  eventId: 'event-1',
  token: 'anonymous-token',
);
const _message = PushMessage(
  title: 'Nuevo gasto',
  body: 'Ana agregó bebidas',
  eventId: 'event-1',
);

class _AuthNotifier extends AuthNotifier {
  _AuthNotifier()
    : super(
        FakeAuthRepository(delay: Duration.zero),
        FakeSecureStorage(),
        notificationsRepository: FakeNotificationsRepository(
          delay: Duration.zero,
        ),
        getPushToken: () async => null,
      );

  void setSession(UserSession? session) {
    state = session == null
        ? const AuthUnauthenticated()
        : AuthAuthenticated(session);
  }

  void setAuthState(AuthState next) => state = next;
}

void main() {
  late FakePushMessagingService messaging;
  late _AuthNotifier auth;
  late ProviderContainer container;
  late GlobalKey<NavigatorState> navigatorKey;
  late GlobalKey<ScaffoldMessengerState> messengerKey;
  late int unreadLoads;

  setUp(() {
    messaging = FakePushMessagingService();
    auth = _AuthNotifier();
    navigatorKey = GlobalKey<NavigatorState>();
    messengerKey = GlobalKey<ScaffoldMessengerState>();
    unreadLoads = 0;
    container = ProviderContainer(
      overrides: [
        pushMessagingServiceProvider.overrideWithValue(messaging),
        authNotifierProvider.overrideWith((ref) => auth),
        unreadCountsProvider.overrideWith((ref) async {
          unreadLoads++;
          return UnreadCounts(byEvent: const {}, byGroup: const {});
        }),
        eventsRepositoryProvider.overrideWithValue(
          FakeEventsRepository(delay: Duration.zero),
        ),
        expensesRepositoryProvider.overrideWithValue(
          FakeExpensesRepository(delay: Duration.zero),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await messaging.dispose();
  });

  Future<void> showApp(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: messengerKey,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => ForegroundPushListener(
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: messengerKey,
            child: OpenedPushListener(
              navigatorKey: navigatorKey,
              child: child!,
            ),
          ),
          home: Consumer(
            builder: (context, ref, child) {
              ref.watch(unreadCountsProvider);
              return const Scaffold(body: Text('Inicio'));
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el push, actualiza contadores y abre el evento', (
    tester,
  ) async {
    auth.setSession(_organizer);
    await showApp(tester);
    final loadsBeforeMessage = unreadLoads;

    messaging.emitForegroundMessage(_message);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Nuevo gasto'), findsOneWidget);
    expect(find.text('Ana agregó bebidas'), findsOneWidget);
    expect(find.text('Ver'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).behavior,
      SnackBarBehavior.floating,
    );
    expect(unreadLoads, greaterThan(loadsBeforeMessage));

    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EventDetailScreen>(find.byType(EventDetailScreen)).eventId,
      'event-1',
    );

    final loadsBeforeReturn = unreadLoads;
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(unreadLoads, greaterThan(loadsBeforeReturn));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ignora mensajes sin sesión de organizador', (tester) async {
    auth.setSession(_anonymous);
    await showApp(tester);
    final loadsBeforeMessage = unreadLoads;
    messaging.emitForegroundMessage(_message);
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
    expect(unreadLoads, loadsBeforeMessage);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('la acción no abre el evento si la sesión cambió', (
    tester,
  ) async {
    auth.setSession(_organizer);
    await showApp(tester, locale: const Locale('en'));
    messaging.emitForegroundMessage(_message);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('View'), findsOneWidget);
    auth.setSession(_anonymous);
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailScreen), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('una notificación tocada en segundo plano abre su evento', (
    tester,
  ) async {
    auth.setSession(_organizer);
    await showApp(tester);
    expect(messaging.getInitialMessageCalls, 1);
    messaging.emitMessageOpened(_message);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EventDetailScreen>(find.byType(EventDetailScreen)).eventId,
      'event-1',
    );
    final loadsBeforeReturn = unreadLoads;
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(unreadLoads, greaterThan(loadsBeforeReturn));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('un arranque desde push espera a que se restaure la sesión', (
    tester,
  ) async {
    auth.setAuthState(const AuthCheckingInitialSession());
    messaging.initialMessage = _message;
    await showApp(tester);
    expect(messaging.getInitialMessageCalls, 1);
    expect(find.byType(EventDetailScreen), findsNothing);
    auth.setSession(_organizer);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EventDetailScreen>(find.byType(EventDetailScreen)).eventId,
      'event-1',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('un arranque sin sesión descarta la notificación pendiente', (
    tester,
  ) async {
    auth.setAuthState(const AuthCheckingInitialSession());
    messaging.initialMessage = _message;
    await showApp(tester);
    auth.setSession(null);
    await tester.pumpAndSettle();
    auth.setSession(_organizer);
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailScreen), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
