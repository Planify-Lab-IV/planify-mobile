import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/core/theme/app_colors.dart';
import 'package:planify/core/theme/app_radius.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/auth_exceptions.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/auth/presentation/screens/login_screen.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/events/data/events_repository_provider.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/home/presentation/screens/participant_home_screen.dart';
import 'package:planify/features/home/presentation/screens/registered_home_shell.dart';
import 'package:planify/features/splash/presentation/controllers/splash_providers.dart';
import 'package:planify/features/splash/presentation/screens/splash_screen.dart';
import 'package:planify/main.dart';

import '../unit/deep_link_service_test.dart';

Widget testApp(
  FakeAuthRepository repository,
  FakeSecureStorage storage, {
  VoidCallback? onSplashFinished,
}) => ProviderScope(
  overrides: [
    appLinksProvider.overrideWithValue(FakeAppLinks()),
    authRepositoryProvider.overrideWithValue(repository),
    secureStorageProvider.overrideWithValue(storage),
    eventsRepositoryProvider.overrideWithValue(
      FakeEventsRepository(delay: Duration.zero),
    ),
  ],
  child: MyApp(
    onSplashFinished: onSplashFinished,
    startPushRegistration: false,
  ),
);

void main() {
  testWidgets('libera el primer frame al resolver auth sin esperar al PNG', (
    tester,
  ) async {
    var frameReady = false;
    final repository = _ControlledSessionRepository();
    await tester.pumpWidget(
      testApp(
        repository,
        _MemoryStorage(),
        onSplashFinished: () => frameReady = true,
      ),
    );
    expect(frameReady, isFalse);
    repository.session.complete(null);
    await tester.pump();
    await tester.pump();
    expect(frameReady, isTrue);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets(
    'libera el primer frame al vencer la marca aunque auth siga pendiente',
    (tester) async {
      var frameReady = false;
      final repository = _ControlledSessionRepository();
      await tester.pumpWidget(
        testApp(
          repository,
          _MemoryStorage(),
          onSplashFinished: () => frameReady = true,
        ),
      );
      expect(frameReady, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(frameReady, isTrue);
      expect(find.byKey(const Key('auth_loading_screen')), findsOneWidget);
      repository.session.complete(null);
      await tester.pumpAndSettle();
    },
  );

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('logo sin texto sobre primary, centrado en $platform', (
      tester,
    ) async {
      await tester.runAsync(() => SplashScreen.precacheLogo(platform));
      final imageKey = await AssetImage(
        SplashScreen.assetForPlatform(platform),
      ).obtainKey(ImageConfiguration.empty);
      expect(PaintingBinding.instance.imageCache.containsKey(imageKey), isTrue);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light.copyWith(platform: platform),
          home: const SplashScreen(),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        platform == TargetPlatform.android
            ? SplashScreen.androidAsset
            : SplashScreen.classicAsset,
      );
      expect(image.width, AppDimens.splashLogoSize);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppColors.primary,
      );
      expect(
        tester.getCenter(find.byType(Image)),
        tester.getCenter(find.byType(Scaffold)),
      );
      expect(find.byType(Text), findsNothing);
    });
  }

  testWidgets('sin token muestra splash y va a login sin duración mínima', (
    tester,
  ) async {
    final storage = _MemoryStorage();
    await tester.pumpWidget(
      testApp(
        FakeAuthRepository(
          storage: storage,
          delay: const Duration(milliseconds: 100),
        ),
        storage,
      ),
    );
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('red lenta pasa a carga a los dos segundos y luego al home', (
    tester,
  ) async {
    final storage = _MemoryStorage();
    await storage.saveToken('fake-guest-token:Invitado:evt-123:0');
    final repository = FakeAuthRepository(
      storage: storage,
      delay: const Duration(seconds: 3),
    );
    await tester.pumpWidget(testApp(repository, storage));
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byKey(const Key('auth_loading_screen')), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(ParticipantHomeScreen), findsOneWidget);
  });

  testWidgets('organizador va directamente a su home', (tester) async {
    final storage = _MemoryStorage();
    final repository = _ControlledSessionRepository();
    await tester.pumpWidget(testApp(repository, storage));
    expect(find.byType(SplashScreen), findsOneWidget);
    repository.session.complete(
      const OrganizerSession(
        userId: 'user-1',
        name: 'Lucas',
        email: 'lucas@example.com',
        username: 'lucas',
        token: 'token',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RegisteredHomeShell), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  for (final exception in [
    const InvalidStoredSessionException(),
    const NetworkAuthException(),
  ]) {
    testWidgets('sale de splash ante $exception', (tester) async {
      final storage = _MemoryStorage();
      await storage.saveToken('stored-token');
      final repository = _ControlledSessionRepository();
      await tester.pumpWidget(testApp(repository, storage));
      repository.session.completeError(exception);
      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        await storage.getToken(),
        exception is NetworkAuthException ? 'stored-token' : null,
      );
    });
  }

  testWidgets('nuevo ProviderScope vuelve a mostrar splash', (tester) async {
    final storage = _MemoryStorage();
    await storage.saveToken('fake-guest-token:Invitado:evt-123:0');
    await tester.pumpWidget(
      testApp(
        FakeAuthRepository(
          storage: storage,
          delay: const Duration(milliseconds: 100),
        ),
        storage,
      ),
    );
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      testApp(
        FakeAuthRepository(
          storage: storage,
          delay: const Duration(milliseconds: 100),
        ),
        storage,
      ),
    );
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.byType(ParticipantHomeScreen), findsOneWidget);
  });

  testWidgets('volver del segundo plano no reinicia splash', (tester) async {
    final storage = _MemoryStorage();
    await tester.pumpWidget(
      testApp(
        FakeAuthRepository(storage: storage, delay: Duration.zero),
        storage,
      ),
    );
    await tester.pumpAndSettle();
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('login y logout usan carga sin volver a splash', (tester) async {
    final storage = _MemoryStorage();
    final repository = FakeAuthRepository(
      storage: storage,
      delay: const Duration(milliseconds: 100),
    );
    await tester.pumpWidget(testApp(repository, storage));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MyApp)),
    );
    final notifier = container.read(authNotifierProvider.notifier);
    final login = notifier.login(identifier: 'lucas', password: 'password123');
    await tester.pump();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byKey(const Key('auth_loading_screen')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await login;
    await tester.pumpAndSettle();
    final logout = notifier.logout();
    await tester.pump();
    expect(find.byType(SplashScreen), findsNothing);
    expect(container.read(splashNotifierProvider), SplashPhase.completed);
    await tester.pump(const Duration(milliseconds: 100));
    await logout;
    await tester.pumpAndSettle();
  });

  for (final anonymous in [false, true]) {
    testWidgets(
      '${anonymous ? 'ingreso anónimo' : 'registro'} no vuelve a splash',
      (tester) async {
        final storage = _MemoryStorage();
        final repository = FakeAuthRepository(
          storage: storage,
          delay: const Duration(milliseconds: 100),
        );
        await tester.pumpWidget(testApp(repository, storage));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MyApp)),
        );
        final notifier = container.read(authNotifierProvider.notifier);
        final action = anonymous
            ? notifier.loginAnonymously(
                name: 'Invitado',
                pin: '1234',
                eventId: 'evt-123',
              )
            : notifier.register(
                name: 'Lucía',
                username: 'lucia',
                email: 'lucia@planify.com',
                password: 'password123',
              );
        await tester.pump();
        expect(find.byType(SplashScreen), findsNothing);
        expect(find.byKey(const Key('auth_loading_screen')), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 100));
        await action;
        await tester.pumpAndSettle();
        expect(find.byType(SplashScreen), findsNothing);
      },
    );
  }
}

class _ControlledSessionRepository extends FakeAuthRepository {
  final session = Completer<UserSession?>();

  _ControlledSessionRepository() : super(delay: Duration.zero);

  @override
  Future<UserSession?> getCurrentSession() => session.future;
}

/// El delay de estos tests pertenece al repositorio, no al almacenamiento.
class _MemoryStorage extends FakeSecureStorage {
  String? _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> deleteToken() async => _token = null;
}
