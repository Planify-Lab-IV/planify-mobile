import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:planify/l10n/app_localizations.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/auth/presentation/controllers/auth_state.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/screens/login_screen.dart';
import 'package:planify/features/home/presentation/screens/organizer_home_screen.dart';
import 'package:planify/features/home/presentation/screens/participant_home_screen.dart';
import 'package:planify/features/home/presentation/screens/registered_home_shell.dart';
import 'package:planify/features/home/presentation/controllers/registered_home_tab_provider.dart';
import 'package:planify/features/invitations/presentation/controllers/invitation_providers.dart';
import 'package:planify/features/invitations/presentation/controllers/invitation_state.dart';
import 'package:planify/features/notifications/presentation/controllers/push_registration_notifier.dart';
import 'package:planify/features/notifications/presentation/widgets/foreground_push_listener.dart';
import 'package:planify/features/notifications/presentation/widgets/opened_push_listener.dart';
import 'package:planify/features/splash/presentation/controllers/splash_providers.dart';
import 'package:planify/features/splash/presentation/screens/splash_screen.dart';

Future<void> main() async {
  final startupClock = Stopwatch()..start();
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
  }
  var firstFrameAllowed = false;
  void allowStartupFrame() {
    if (firstFrameAllowed) return;
    firstFrameAllowed = true;
    binding.allowFirstFrame();
  }

  runApp(
    ProviderScope(
      overrides: [
        startupElapsedProvider.overrideWith((ref) => startupClock.elapsed),
      ],
      child: MyApp(onSplashFinished: allowStartupFrame),
    ),
  );
  try {
    // Precarga el PNG mientras la marca está visible; onSplashFinished libera
    // el frame antes si auth termina o vence el plazo. Auth y los deep links
    // arrancan en paralelo desde MyApp.initState.
    await SplashScreen.precacheLogo(
      defaultTargetPlatform,
    ).timeout(SplashNotifier.maximumDuration);
  } catch (_) {
    // Un asset fallido o lento nunca debe retener el primer frame para siempre.
  } finally {
    allowStartupFrame();
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({
    super.key,
    this.onSplashFinished,
    this.startPushRegistration = true,
  });

  /// Permite retirar el launch si el siguiente destino está listo antes del PNG.
  final VoidCallback? onSplashFinished;

  /// Permite aislar los plugins nativos en widget tests que no cubren push.
  final bool startPushRegistration;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool get _pushEnabled =>
      widget.startPushRegistration &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    ref.read(splashNotifierProvider);
    if (widget.onSplashFinished != null) {
      ref.listenManual<SplashPhase>(splashNotifierProvider, (previous, next) {
        if (next != SplashPhase.brand) widget.onSplashFinished?.call();
      }, fireImmediately: true);
    }
    if (_pushEnabled) {
      ref.read(pushRegistrationNotifierProvider);
    }
    // Inicia la escucha centralizada de deep links al arrancar la app
    ref.read(deepLinkServiceProvider).listen((uri) {
      ref.read(invitationNotifierProvider.notifier).handleDeepLink(uri);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Al autenticarse, limpia cualquier invitación pendiente para que no quede en memoria
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        ref.read(invitationNotifierProvider.notifier).clearInvitation();
      }
      if (next is AuthUnauthenticated) {
        ref.read(registeredHomeSelectedTabProvider.notifier).state = 0;
      }
    });

    final currentLocale = ref.watch(localeNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final splashPhase = ref.watch(splashNotifierProvider);
    final invitationState = ref.watch(invitationNotifierProvider);

    final resolvedEventId = switch (invitationState) {
      InvitationResolved(:final eventId) => eventId,
      _ => null,
    };

    return MaterialApp(
      title: 'Planify',
      theme: AppTheme.light,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      builder: _pushEnabled
          ? (context, child) => ForegroundPushListener(
              navigatorKey: _navigatorKey,
              scaffoldMessengerKey: _scaffoldMessengerKey,
              child: OpenedPushListener(
                navigatorKey: _navigatorKey,
                child: child!,
              ),
            )
          : null,

      // Configuración de idiomas
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations
            .delegate, // traduce DatePicker, TimePicker, etc.
        GlobalWidgetsLocalizations
            .delegate, // maneja la dir en la que se lee el texto
        GlobalCupertinoLocalizations
            .delegate, // cupertino equivale a estilo visual de apple, traduce esos elementos
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Si currentLocale es null, toma automáticamente el idioma del celular
      locale: currentLocale,

      // Enrutamiento reactivo según el estado de autenticación
      home: homeForAuthState(
        authState: authState,
        splashPhase: splashPhase,
        resolvedEventId: resolvedEventId,
      ),
    );
  }
}

Widget homeForAuthState({
  required AuthState authState,
  SplashPhase splashPhase = SplashPhase.completed,
  String? resolvedEventId,
}) {
  return switch (authState) {
    AuthCheckingInitialSession() when splashPhase == SplashPhase.brand =>
      const SplashScreen(),
    AuthAuthenticated(session: final OrganizerSession session) =>
      RegisteredHomeShell(home: OrganizerHomeScreen(session: session)),
    AuthAuthenticated(session: final AnonymousSession session) =>
      ParticipantHomeScreen(session: session),
    AuthLoading() || AuthCheckingInitialSession() => const Scaffold(
      key: Key('auth_loading_screen'),
      body: Center(child: CircularProgressIndicator()),
    ),
    _ => LoginScreen(eventId: resolvedEventId),
  };
}
