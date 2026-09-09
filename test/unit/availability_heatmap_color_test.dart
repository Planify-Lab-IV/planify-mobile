import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/availability/presentation/widgets/availability_heatmap_color.dart';

void main() {
  const primaryContainer = Color(0xffdbeafe);
  const primary = Color(0xff296cf2);

  Color resolve({required int availableCount, required int totalParticipants}) {
    return resolveAvailabilityHeatmapColor(
      primaryContainer: primaryContainer,
      primary: primary,
      availableCount: availableCount,
      totalParticipants: totalParticipants,
    );
  }

  group('resolveAvailabilityHeatmapColor', () {
    test('uses the base color when nobody is available', () {
      expect(
        resolve(availableCount: 0, totalParticipants: 5),
        primaryContainer,
      );
    });

    test('uses the primary color when everyone is available', () {
      expect(resolve(availableCount: 5, totalParticipants: 5), primary);
    });

    test('interpolates the color for partial availability', () {
      expect(
        resolve(availableCount: 3, totalParticipants: 5),
        Color.lerp(primaryContainer, primary, 0.6),
      );
    });

    test('uses the base color when there are no participants', () {
      expect(
        resolve(availableCount: 0, totalParticipants: 0),
        primaryContainer,
      );
    });

    test('limits inconsistent counts to the supported color range', () {
      expect(resolve(availableCount: 7, totalParticipants: 5), primary);
      expect(
        resolve(availableCount: -1, totalParticipants: 5),
        primaryContainer,
      );
    });
  });
}
