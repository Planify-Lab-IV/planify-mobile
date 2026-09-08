import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/availability/domain/availability_heatmap_dto.dart';
import 'package:planify/features/availability/domain/slot_heatmap_dto.dart';
import 'package:planify/features/availability/presentation/widgets/availability_heatmap_grid.dart';

void main() {
  const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  Widget buildGrid({
    String Function(int availableCount)? tooltipMessageBuilder,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 350,
          child: AvailabilityHeatmapGrid(
            heatmap: AvailabilityHeatmapDto(
              totalParticipants: 5,
              slots: [
                SlotHeatmapDto(weekDay: 0, hourBlock: 0, availableCount: 0),
                SlotHeatmapDto(weekDay: 1, hourBlock: 0, availableCount: 3),
                SlotHeatmapDto(weekDay: 2, hourBlock: 0, availableCount: 5),
              ],
            ),
            dayLabels: dayLabels,
            tooltipMessageBuilder: tooltipMessageBuilder,
          ),
        ),
      ),
    );
  }

  Color colorFor(WidgetTester tester, Key key) {
    return (tester.widget<Container>(find.byKey(key)).decoration!
            as BoxDecoration)
        .color!;
  }

  testWidgets('uses theme colors for zero, partial, and full availability', (
    tester,
  ) async {
    await tester.pumpWidget(buildGrid());

    final colorScheme = Theme.of(
      tester.element(find.byKey(const Key('availability_heatmap_grid'))),
    ).colorScheme;

    expect(
      colorFor(tester, const Key('availability_heatmap_slot_0_0')),
      colorScheme.primaryContainer,
    );
    expect(
      colorFor(tester, const Key('availability_heatmap_slot_1_0')),
      Color.lerp(colorScheme.primaryContainer, colorScheme.primary, 0.6),
    );
    expect(
      colorFor(tester, const Key('availability_heatmap_slot_2_0')),
      colorScheme.primary,
    );
  });

  testWidgets('uses the base color for slots absent from the heatmap', (
    tester,
  ) async {
    await tester.pumpWidget(buildGrid());

    final colorScheme = Theme.of(
      tester.element(find.byKey(const Key('availability_heatmap_grid'))),
    ).colorScheme;

    expect(
      colorFor(tester, const Key('availability_heatmap_slot_3_0')),
      colorScheme.primaryContainer,
    );
  });

  testWidgets('can expose the exact count through a localized tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildGrid(
        tooltipMessageBuilder: (availableCount) {
          return '$availableCount disponibles';
        },
      ),
    );

    final tooltip = tester.widget<Tooltip>(
      find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message == '3 disponibles',
      ),
    );

    expect(tooltip.message, '3 disponibles');
    expect(tooltip.waitDuration, Duration.zero);
  });

  testWidgets('shows the exact count when a mouse hovers over a slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildGrid(
        tooltipMessageBuilder: (availableCount) {
          return '$availableCount disponibles';
        },
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(
      tester.getCenter(
        find.byKey(const Key('availability_heatmap_slot_1_0')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('3 disponibles'), findsOneWidget);
  });
}
