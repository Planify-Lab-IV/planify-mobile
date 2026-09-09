import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_radius.dart';
import 'package:planify/core/theme/app_spacing.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/availability/domain/slot.dart';
import 'package:planify/features/availability/presentation/widgets/availability_grid.dart';

void main() {
  const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  Widget buildGrid({
    Set<Slot> selectedSlots = const {},
    required ValueChanged<Slot> onToggleSlot,
    required ValueChanged<Slot> onMarkSlot,
    bool isEnabled = true,
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
            isEnabled: isEnabled,
            dayLabels: dayLabels,
          ),
        ),
      ),
    );
  }

  testWidgets('tap maps a grid cell to its slot', (tester) async {
    final toggledSlots = <Slot>[];

    await tester.pumpWidget(
      buildGrid(onToggleSlot: toggledSlots.add, onMarkSlot: (_) {}),
    );

    await tester.tap(find.byKey(const Key('availability_slot_3_0')));

    expect(toggledSlots, [Slot(dayOfWeek: 3, hour: 0)]);
  });

  testWidgets('does not accept slot interactions while disabled', (
    tester,
  ) async {
    final toggledSlots = <Slot>[];
    final markedSlots = <Slot>{};

    await tester.pumpWidget(
      buildGrid(
        isEnabled: false,
        onToggleSlot: toggledSlots.add,
        onMarkSlot: markedSlots.add,
      ),
    );

    final firstCell = find.byKey(const Key('availability_slot_3_0'));
    final secondCell = find.byKey(const Key('availability_slot_4_0'));
    await tester.tap(firstCell);
    final gesture = await tester.startGesture(tester.getCenter(firstCell));
    await tester.pump(kLongPressTimeout);
    await gesture.moveTo(tester.getCenter(secondCell));
    await gesture.up();

    expect(toggledSlots, isEmpty);
    expect(markedSlots, isEmpty);
  });

  testWidgets('long press and drag marks slots horizontally without toggling', (
    tester,
  ) async {
    final markedSlots = <Slot>{};

    await tester.pumpWidget(
      buildGrid(onToggleSlot: (_) {}, onMarkSlot: markedSlots.add),
    );

    final firstCell = find.byKey(const Key('availability_slot_0_0'));
    final secondCell = find.byKey(const Key('availability_slot_1_0'));
    final thirdCell = find.byKey(const Key('availability_slot_2_0'));
    final gesture = await tester.startGesture(tester.getCenter(firstCell));
    await tester.pump(kLongPressTimeout);
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

  testWidgets('long press and drag marks slots vertically without toggling', (
    tester,
  ) async {
    final markedSlots = <Slot>{};

    await tester.pumpWidget(
      buildGrid(onToggleSlot: (_) {}, onMarkSlot: markedSlots.add),
    );

    final firstCell = find.byKey(const Key('availability_slot_0_0'));
    final secondCell = find.byKey(const Key('availability_slot_0_1'));
    final thirdCell = find.byKey(const Key('availability_slot_0_2'));
    final gesture = await tester.startGesture(tester.getCenter(firstCell));
    await tester.pump(kLongPressTimeout);
    await gesture.moveTo(tester.getCenter(secondCell));
    await gesture.moveTo(tester.getCenter(thirdCell));
    await gesture.up();

    expect(
      markedSlots,
      containsAll([
        Slot(dayOfWeek: 0, hour: 0),
        Slot(dayOfWeek: 0, hour: 1),
        Slot(dayOfWeek: 0, hour: 2),
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

  testWidgets('displays an aligned hour label for each grid row', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildGrid(onToggleSlot: (_) {}, onMarkSlot: (_) {}),
    );

    expect(find.byKey(const Key('availability_hour_0')), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.byKey(const Key('availability_hour_1')), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget);
  });

  testWidgets('groups labels and slots in a rounded card with spaced slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildGrid(onToggleSlot: (_) {}, onMarkSlot: (_) {}),
    );

    final card = tester.widget<Card>(find.byType(Card));
    final cardShape = card.shape! as RoundedRectangleBorder;
    final grid = tester.widget<GridView>(
      find.byKey(const Key('availability_grid')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    final decoration =
        tester
                .widget<Container>(
                  find.byKey(const Key('availability_slot_0_0')),
                )
                .decoration!
            as BoxDecoration;

    expect(cardShape.borderRadius, BorderRadius.circular(AppRadius.card));
    expect(delegate.crossAxisSpacing, AppSpacing.sm);
    expect(delegate.mainAxisSpacing, AppSpacing.sm);
    expect(delegate.childAspectRatio, 1.25);
    expect(delegate.crossAxisCount, 8);
    expect(decoration.borderRadius, BorderRadius.circular(6));
  });
}
