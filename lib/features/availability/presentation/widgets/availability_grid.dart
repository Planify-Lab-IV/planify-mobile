import 'package:flutter/material.dart';

import '../../domain/slot.dart';
import 'weekly_availability_grid.dart';

class AvailabilityGrid extends StatefulWidget {
  final Set<Slot> selectedSlots;
  final ValueChanged<Slot> onToggleSlot;
  final ValueChanged<Slot> onMarkSlot;
  final List<String> dayLabels;

  const AvailabilityGrid({
    super.key,
    required this.selectedSlots,
    required this.onToggleSlot,
    required this.onMarkSlot,
    required this.dayLabels,
  }) : assert(dayLabels.length == WeeklyAvailabilityGrid.dayCount);

  @override
  State<AvailabilityGrid> createState() => _AvailabilityGridState();
}

class _AvailabilityGridState extends State<AvailabilityGrid> {
  Slot? _dragStartSlot;

  Slot? _slotAt(
    Offset position,
    double gridWidth,
    double scrollOffset,
  ) {
    final cellWidth =
        (gridWidth -
            (WeeklyAvailabilityGrid.slotSpacing *
                (WeeklyAvailabilityGrid.dayCount - 1))) /
        WeeklyAvailabilityGrid.dayCount;
    final cellHeight = cellWidth / WeeklyAvailabilityGrid.slotAspectRatio;
    final cellStride = cellWidth + WeeklyAvailabilityGrid.slotSpacing;
    final rowStride = cellHeight + WeeklyAvailabilityGrid.slotSpacing;
    final contentY = position.dy + scrollOffset;
    final dayOfWeek = (position.dx / cellStride).floor();
    final hour = (contentY / rowStride).floor();

    final isInColumnGap = position.dx - (dayOfWeek * cellStride) > cellWidth;
    final isInRowGap = contentY - (hour * rowStride) > cellHeight;

    if (dayOfWeek < 0 ||
        dayOfWeek >= WeeklyAvailabilityGrid.dayCount ||
        hour < 0 ||
        hour >= WeeklyAvailabilityGrid.hourCount ||
        isInColumnGap ||
        isInRowGap) {
      return null;
    }
    return Slot(dayOfWeek: dayOfWeek, hour: hour);
  }

  void _toggleAt(Offset position, double gridWidth, double scrollOffset) {
    final slot = _slotAt(position, gridWidth, scrollOffset);
    if (slot != null) widget.onToggleSlot(slot);
  }

  void _markAt(Offset position, double gridWidth, double scrollOffset) {
    final slot = _slotAt(position, gridWidth, scrollOffset);
    if (slot != null) widget.onMarkSlot(slot);
  }

  void _rememberDragStart(
    Offset position,
    double gridWidth,
    double scrollOffset,
  ) {
    _dragStartSlot = _slotAt(position, gridWidth, scrollOffset);
  }

  void _markDragStart() {
    final slot = _dragStartSlot;
    if (slot != null) widget.onMarkSlot(slot);
  }

  @override
  Widget build(BuildContext context) {
    return WeeklyAvailabilityGrid(
      dayLabels: widget.dayLabels,
      cellBuilder: (context, slot) {
        final isSelected = widget.selectedSlots.contains(slot);
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          key: Key('availability_slot_${slot.dayOfWeek}_${slot.hour}'),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(
              WeeklyAvailabilityGrid.slotBorderRadius,
            ),
          ),
        );
      },
      interactionBuilder: (context, constraints, scrollController, grid) {
        return Listener(
          onPointerDown: (event) => _rememberDragStart(
            event.localPosition,
            constraints.maxWidth,
            scrollController.offset,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              _toggleAt(
                details.localPosition,
                constraints.maxWidth,
                scrollController.offset,
              );
              _dragStartSlot = null;
            },
            onPanStart: (details) {
              _markDragStart();
              _markAt(
                details.localPosition,
                constraints.maxWidth,
                scrollController.offset,
              );
            },
            onPanUpdate: (details) => _markAt(
              details.localPosition,
              constraints.maxWidth,
              scrollController.offset,
            ),
            onPanEnd: (_) => _dragStartSlot = null,
            onPanCancel: () => _dragStartSlot = null,
            child: grid,
          ),
        );
      },
    );
  }
}
