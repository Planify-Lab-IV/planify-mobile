import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/controllers/auth_state.dart';
import 'package:planify/features/home/presentation/screens/participant_home_screen.dart';
import 'package:planify/features/home/presentation/screens/registered_home_shell.dart';
import 'package:planify/main.dart';

void main() {
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
