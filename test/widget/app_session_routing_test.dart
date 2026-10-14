import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/controllers/auth_state.dart';
import 'package:planify/features/home/presentation/screens/participant_home_screen.dart';
import 'package:planify/features/home/presentation/screens/registered_home_shell.dart';
import 'package:planify/main.dart';
import 'package:flutter/material.dart';
import 'package:planify/features/auth/presentation/screens/login_screen.dart';
import 'package:planify/features/splash/presentation/controllers/splash_providers.dart';
import 'package:planify/features/splash/presentation/screens/splash_screen.dart';

void main() {
  test('splash sólo corresponde al chequeo inicial dentro del plazo', () {
    expect(
      homeForAuthState(
        authState: const AuthCheckingInitialSession(),
        splashPhase: SplashPhase.brand,
      ),
      isA<SplashScreen>(),
    );
    for (final phase in [SplashPhase.loading, SplashPhase.completed]) {
      expect(
        homeForAuthState(
          authState: const AuthCheckingInitialSession(),
          splashPhase: phase,
        ),
        isA<Scaffold>(),
      );
    }
    for (final phase in SplashPhase.values) {
      expect(
        homeForAuthState(authState: const AuthLoading(), splashPhase: phase),
        isNot(isA<SplashScreen>()),
      );
    }
  });

  test('login conserva la invitación al terminar el chequeo', () {
    final home = homeForAuthState(
      authState: const AuthUnauthenticated(),
      resolvedEventId: 'evt-123',
    );
    expect(home, isA<LoginScreen>());
    expect((home as LoginScreen).eventId, 'evt-123');
  });

  test('a registered session uses the shell that exposes Balances', () {
    final home = homeForAuthState(
      authState: const AuthAuthenticated(
        OrganizerSession(
          userId: 'user-1',
          name: 'dev1',
          email: 'dev1@planify.dev',
          username: 'dev1',
          token: 'registered-token',
        ),
      ),
    );

    expect(home, isA<RegisteredHomeShell>());
  });

  test('an anonymous session does not use the shell that exposes Balances', () {
    final home = homeForAuthState(
      authState: const AuthAuthenticated(
        AnonymousSession(
          participantId: 'participant-1',
          name: 'Invitado',
          eventId: 'event-1',
          token: 'anonymous-token',
        ),
      ),
    );

    expect(home, isA<ParticipantHomeScreen>());
    expect(home, isNot(isA<RegisteredHomeShell>()));
  });
}
