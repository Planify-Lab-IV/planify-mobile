import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/availability/domain/slot.dart';
import 'package:planify/features/availability/presentation/widgets/availability_grid.dart';

void main() {
  const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  Widget buildGrid({
    Set<Slot> selectedSlots = const {},
    required ValueChanged<Slot> onToggleSlot,
    required ValueChanged<Slot> onMarkSlot,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 350,
          child: AvailabilityGrid(
            selectedSlots: selectedSlots,
            onToggleSlot: onToggleSlot,
            onMarkSlot: onMarkSlot,
            dayLabels: dayLabels,
          ),
        ),
      ),
    );
  }

  testWidgets('tap maps a grid cell to its slot', (tester) async {
    final toggledSlots = <Slot>[];

    await tester.pumpWidget(
      buildGrid(
        onToggleSlot: toggledSlots.add,
        onMarkSlot: (_) {},
      ),
    );

    await tester.tap(find.byKey(const Key('availability_slot_3_0')));

    expect(toggledSlots, [Slot(dayOfWeek: 3, hour: 0)]);
  });

  testWidgets('drag marks each slot it crosses without toggling', (tester) async {
    final markedSlots = <Slot>{};

    await tester.pumpWidget(
      buildGrid(
        onToggleSlot: (_) {},
        onMarkSlot: markedSlots.add,
      ),
    );

    final firstCell = find.byKey(const Key('availability_slot_0_0'));
    final secondCell = find.byKey(const Key('availability_slot_1_0'));
    final thirdCell = find.byKey(const Key('availability_slot_2_0'));
    final gesture = await tester.startGesture(tester.getCenter(firstCell));
    await gesture.moveTo(tester.getCenter(secondCell));
    await gesture.moveTo(tester.getCenter(thirdCell));
    await gesture.up();

    expect(
      markedSlots,
      containsAll([
        Slot(dayOfWeek: 0, hour: 0),
        Slot(dayOfWeek: 1, hour: 0),
        Slot(dayOfWeek: 2, hour: 0),
      ]),
    );
  });

  testWidgets('uses theme colors for selected and unselected cells', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildGrid(
        selectedSlots: {Slot(dayOfWeek: 0, hour: 0)},
        onToggleSlot: (_) {},
        onMarkSlot: (_) {},
      ),
    );

    final selectedFinder = find.byKey(const Key('availability_slot_0_0'));
    final unselectedFinder = find.byKey(const Key('availability_slot_1_0'));
    final colorScheme = Theme.of(tester.element(selectedFinder)).colorScheme;
    final selectedDecoration =
        tester.widget<Container>(selectedFinder).decoration! as BoxDecoration;
    final unselectedDecoration =
        tester.widget<Container>(unselectedFinder).decoration! as BoxDecoration;

    expect(selectedDecoration.color, colorScheme.primary);
    expect(unselectedDecoration.color, colorScheme.surfaceContainerHighest);
  });
}
