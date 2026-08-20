import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme(ColorScheme scheme) {
    final base = GoogleFonts.poppinsTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: 57, height: 64 / 57, color: scheme.onPrimaryContainer),
      displayMedium: base.displayMedium?.copyWith(fontSize: 45, height: 52 / 45, color: scheme.onPrimaryContainer),
      displaySmall: base.displaySmall?.copyWith(fontSize: 36, height: 44 / 36, color: scheme.onPrimaryContainer),

      headlineLarge: base.headlineLarge?.copyWith(fontSize: 32, height: 40 / 32, color: scheme.onPrimaryContainer),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 28, height: 36 / 28, color: scheme.onPrimaryContainer),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: 24, height: 32 / 24, color: scheme.onPrimaryContainer),

      titleLarge: base.titleLarge?.copyWith(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w400, color: scheme.onPrimaryContainer),
      titleMedium: base.titleMedium?.copyWith(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w500, color: scheme.onPrimaryContainer),
      titleSmall: base.titleSmall?.copyWith(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500, color: scheme.onPrimaryContainer),

      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 24 / 16, color: scheme.onSurface),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 20 / 14, color: scheme.onSurface),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12, height: 16 / 12, color: scheme.onSurfaceVariant),

      labelLarge: base.labelLarge?.copyWith(fontSize: 14, height: 20 / 14, color: scheme.onSurfaceVariant),
      labelMedium: base.labelMedium?.copyWith(fontSize: 12, height: 16 / 12, color: scheme.onSurfaceVariant),
      labelSmall: base.labelSmall?.copyWith(fontSize: 11, height: 16 / 11, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant),
    );
  }
}