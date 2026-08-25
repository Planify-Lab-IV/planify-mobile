import 'package:flutter/material.dart';

class AppColors {
  /*
    Esto es un constructor, el _ lo hace privado, se hace para que la clase no pueda
    ser instanciada (sino podria ser instanciada desde el constructor default)
   */
  AppColors._();

  static const Color primary = Color(0xFF296CF2);
  static const Color secondary = Color(0xFF92C2FC);
  static const Color lightBlue = Color(0xFFDBEAFE);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color darkBlue = Color(0xFF3E579C);
  static const Color background = Color(0xFFECF4FF);

  static const error = Color(0xFFCC5A5A);
  static const success = Color(0xFF3FA873);
  static const onSuccess = Colors.white;
  static const warning = Color(0xFFE3A94A);
  static const onWarning = Colors.white;
  static const danger = Color(0xFFE74C3C);
  static const onDanger = Colors.white;

  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF14162B);
  static const onSurfaceVariant = Color(0xFF6B7280);
  static const outline = Color(0xFFDBEAFE);
}
