import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static final ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.lightBlue,
    onPrimaryContainer: AppColors.darkBlue,
    secondary: AppColors.secondary,
    onSecondary: AppColors.darkBlue,
    secondaryContainer: AppColors.background,
    onSecondaryContainer: AppColors.darkBlue,
    tertiary: AppColors.accent,
    onTertiary: Colors.white,
    tertiaryContainer: Color.lerp(AppColors.accent, Colors.white, 0.8)!,
    onTertiaryContainer: AppColors.onSurface,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: Color.lerp(AppColors.error, Colors.white, 0.8)!,
    onErrorContainer: AppColors.onSurface,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.lightBlue,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
  );

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightScheme,
      textTheme: AppTypography.textTheme(_lightScheme),
      scaffoldBackgroundColor: AppColors.surface,
      cardTheme: const CardThemeData(elevation: 1),
    );
  }
}