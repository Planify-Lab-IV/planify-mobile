import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/slot.dart';

typedef WeeklyAvailabilityGridInteractionBuilder =
    Widget Function(
      BuildContext context,
      BoxConstraints constraints,
      ScrollController scrollController,
      Widget grid,
    );

class WeeklyAvailabilityGrid extends StatefulWidget {
  static const dayCount = 7;
  static const gridColumnCount = dayCount + 1;
  static const hourCount = 24;
  static const slotSpacing = AppSpacing.sm;
  static const slotAspectRatio = 1.25;
  static const slotBorderRadius = 6.0;

  final List<String> dayLabels;
  final Widget Function(BuildContext context, Slot slot) cellBuilder;
  final WeeklyAvailabilityGridInteractionBuilder? interactionBuilder;
  final Key gridKey;

  const WeeklyAvailabilityGrid({
    super.key,
    required this.dayLabels,
    required this.cellBuilder,
    this.interactionBuilder,
    this.gridKey = const Key('availability_grid'),
  }) : assert(dayLabels.length == dayCount);

  @override
  State<WeeklyAvailabilityGrid> createState() => _WeeklyAvailabilityGridState();
}

class _WeeklyAvailabilityGridState extends State<WeeklyAvailabilityGrid> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gridHeight = MediaQuery.sizeOf(context).height * 0.45;

    return Card.outlined(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: SizedBox()),
                const SizedBox(width: WeeklyAvailabilityGrid.slotSpacing),
                for (
                  var index = 0;
                  index < widget.dayLabels.length;
                  index++
                ) ...[
                  Expanded(
                    child: Text(
                      widget.dayLabels[index],
                      style: theme.textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (index < widget.dayLabels.length - 1)
                    const SizedBox(width: WeeklyAvailabilityGrid.slotSpacing),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final grid = SizedBox(
                  height: gridHeight,
                  child: GridView.builder(
                    key: widget.gridKey,
                    controller: _scrollController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              WeeklyAvailabilityGrid.gridColumnCount,
                          crossAxisSpacing: WeeklyAvailabilityGrid.slotSpacing,
                          mainAxisSpacing: WeeklyAvailabilityGrid.slotSpacing,
                          childAspectRatio:
                              WeeklyAvailabilityGrid.slotAspectRatio,
                        ),
                    itemCount:
                        WeeklyAvailabilityGrid.gridColumnCount *
                        WeeklyAvailabilityGrid.hourCount,
                    itemBuilder: (context, index) {
                      final column =
                          index % WeeklyAvailabilityGrid.gridColumnCount;
                      final hour =
                          index ~/ WeeklyAvailabilityGrid.gridColumnCount;

                      if (column == 0) {
                        return Center(
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            key: Key('availability_hour_$hour'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      final slot = Slot(dayOfWeek: column - 1, hour: hour);
                      return widget.cellBuilder(context, slot);
                    },
                  ),
                );

                return widget.interactionBuilder?.call(
                      context,
                      constraints,
                      _scrollController,
                      grid,
                    ) ??
                    grid;
              },
            ),
          ],
        ),
      ),
    );
  }
}
