import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:planify/l10n/app_localizations.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/auth/presentation/controllers/auth_state.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/screens/login_screen.dart';
import 'package:planify/features/home/presentation/screens/organizer_home_screen.dart';
import 'package:planify/features/home/presentation/screens/participant_home_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeNotifierProvider);
    final authState = ref.watch(authNotifierProvider);

    return MaterialApp(
      title: 'Planify',
      theme: AppTheme.light,

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
      home: switch (authState) {
        AuthAuthenticated(session: final OrganizerSession session) =>
          OrganizerHomeScreen(session: session),
        AuthAuthenticated(session: final AnonymousSession session) =>
          ParticipantHomeScreen(session: session),
        AuthLoading() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        _ => const LoginScreen(),
      },
    );
  }
}
