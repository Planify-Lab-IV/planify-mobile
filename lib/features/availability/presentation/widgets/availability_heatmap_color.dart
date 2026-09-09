import 'package:flutter/material.dart';

Color resolveAvailabilityHeatmapColor({
  required Color primaryContainer,
  required Color primary,
  required int availableCount,
  required int totalParticipants,
}) {
  if (totalParticipants <= 0) return primaryContainer;

  final ratio = (availableCount / totalParticipants).clamp(0.0, 1.0).toDouble();
  return Color.lerp(primaryContainer, primary, ratio)!;
}
