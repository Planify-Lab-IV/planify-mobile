import 'package:flutter/material.dart';

import '../../domain/availability_heatmap_dto.dart';
import 'availability_heatmap_color.dart';
import 'weekly_availability_grid.dart';

class AvailabilityHeatmapGrid extends StatelessWidget {
  final AvailabilityHeatmapDto heatmap;
  final List<String> dayLabels;
  final String Function(int availableCount)? tooltipMessageBuilder;

  const AvailabilityHeatmapGrid({
    super.key,
    required this.heatmap,
    required this.dayLabels,
    this.tooltipMessageBuilder,
  }) : assert(dayLabels.length == WeeklyAvailabilityGrid.dayCount);

  @override
  Widget build(BuildContext context) {
    final slotsByPosition = {
      for (final slot in heatmap.slots)
        (slot.weekDay, slot.hourBlock): slot.availableCount,
    };

    return WeeklyAvailabilityGrid(
      gridKey: const Key('availability_heatmap_grid'),
      dayLabels: dayLabels,
      cellBuilder: (context, slot) {
        final availableCount =
            slotsByPosition[(slot.dayOfWeek, slot.hour)] ?? 0;
        final colorScheme = Theme.of(context).colorScheme;
        final cell = Container(
          key: Key('availability_heatmap_slot_${slot.dayOfWeek}_${slot.hour}'),
          decoration: BoxDecoration(
            color: resolveAvailabilityHeatmapColor(
              primaryContainer: colorScheme.primaryContainer,
              primary: colorScheme.primary,
              availableCount: availableCount,
              totalParticipants: heatmap.totalParticipants,
            ),
            borderRadius: BorderRadius.circular(
              WeeklyAvailabilityGrid.slotBorderRadius,
            ),
          ),
        );

        final tooltipMessage = tooltipMessageBuilder?.call(availableCount);
        return tooltipMessage == null
            ? cell
            : Tooltip(message: tooltipMessage, child: cell);
      },
    );
  }
}
