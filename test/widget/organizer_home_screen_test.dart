import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/events/presentation/screens/create_event_step1_screen.dart';
import 'package:planify/features/home/presentation/screens/organizer_home_screen.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  group('OrganizerHomeScreen Widget Tests', () {
    const testSession = UserSession(
      userId: 'usr-123',
      email: 'organizador@planify.com',
      name: 'Lucas',
      role: UserRole.organizer,
      token: 'fake-jwt-token',
    );

    Widget buildHomeScreen() {
      return const ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: OrganizerHomeScreen(session: testSession),
        ),
      );
    }

    testWidgets('renderiza boton Crear nuevo evento y navega al wizard Paso 1', (
      tester,
    ) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create_event_button')), findsOneWidget);
      expect(find.text('Crear nuevo evento'), findsOneWidget);

      await tester.tap(find.byKey(const Key('create_event_button')));
      await tester.pumpAndSettle();

      expect(find.byType(CreateEventStep1Screen), findsOneWidget);
      expect(find.text('Información básica'), findsOneWidget);
    });
  });
}
