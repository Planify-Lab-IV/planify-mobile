import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_radius.dart';
import 'package:planify/core/theme/app_spacing.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/availability/presentation/widgets/weekly_availability_grid.dart';

void main() {
  const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  testWidgets('renders the shared weekly layout and supplies each slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 350,
            child: WeeklyAvailabilityGrid(
              dayLabels: dayLabels,
              cellBuilder: (context, slot) => Container(
                key: Key('shared_slot_${slot.dayOfWeek}_${slot.hour}'),
              ),
            ),
          ),
        ),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    final cardShape = card.shape! as RoundedRectangleBorder;
    final grid = tester.widget<GridView>(
      find.byKey(const Key('availability_grid')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

    expect(find.text('L'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    expect(find.byKey(const Key('shared_slot_0_0')), findsOneWidget);
    expect(cardShape.borderRadius, BorderRadius.circular(AppRadius.card));
    expect(delegate.crossAxisCount, WeeklyAvailabilityGrid.dayCount);
    expect(delegate.crossAxisSpacing, AppSpacing.sm);
    expect(delegate.mainAxisSpacing, AppSpacing.sm);
    expect(delegate.childAspectRatio, WeeklyAvailabilityGrid.slotAspectRatio);
  });
}
