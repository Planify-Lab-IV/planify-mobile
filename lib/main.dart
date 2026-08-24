import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:planify/l10n/app_localizations.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/placeholder_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planify',
      theme: AppTheme.light,

      // Configuración de idiomas
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate, // traduce DatePicker, TimePicker, etc.
        GlobalWidgetsLocalizations.delegate, // maneja la dir en la que se lee el texto
        GlobalCupertinoLocalizations.delegate, // cupertino equivale a estilo visual de apple, traduce esos elementos
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),

      // Pantalla inicial
      home: const PlaceholderScreen(),
    );
  }
}
