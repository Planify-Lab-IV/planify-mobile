import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class PlanifyLogo extends StatelessWidget {
  /// Tamaño total del círculo exterior (por defecto 80.0)
  final double size;

  const PlanifyLogo({super.key, this.size = 80.0});

  @override
  Widget build(BuildContext context) {
    // Calculamos los tamaños internos en proporción al tamaño total:
    final innerSquareSize = size * 0.575; // ~46px si size es 80
    final iconSize = size * 0.325; // ~26px si size es 80

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: innerSquareSize,
        height: innerSquareSize,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          Icons.event_available_rounded,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}
