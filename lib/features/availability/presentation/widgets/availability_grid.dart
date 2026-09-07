import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/slot.dart';

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
  }) : assert(dayLabels.length == 7);

  @override
  State<AvailabilityGrid> createState() => _AvailabilityGridState();
}

class _AvailabilityGridState extends State<AvailabilityGrid> {
  static const _dayCount = 7;
  static const _hourCount = 24;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Slot? _slotAt(Offset position, double gridWidth) {
    final cellWidth = gridWidth / _dayCount;
    final contentY = position.dy + _scrollController.offset;
    final dayOfWeek = (position.dx / cellWidth).floor();
    final hour = (contentY / cellWidth).floor();

    if (dayOfWeek < 0 ||
        dayOfWeek >= _dayCount ||
        hour < 0 ||
        hour >= _hourCount) {
      return null;
    }
    return Slot(dayOfWeek: dayOfWeek, hour: hour);
  }

  void _toggleAt(Offset position, double gridWidth) {
    final slot = _slotAt(position, gridWidth);
    if (slot != null) widget.onToggleSlot(slot);
  }

  void _markAt(Offset position, double gridWidth) {
    final slot = _slotAt(position, gridWidth);
    if (slot != null) widget.onMarkSlot(slot);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gridHeight = MediaQuery.sizeOf(context).height * 0.45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final label in widget.dayLabels)
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) =>
                  _toggleAt(details.localPosition, constraints.maxWidth),
              onPanStart: (details) =>
                  _markAt(details.localPosition, constraints.maxWidth),
              onPanUpdate: (details) =>
                  _markAt(details.localPosition, constraints.maxWidth),
              child: SizedBox(
                height: gridHeight,
                child: GridView.builder(
                  key: const Key('availability_grid'),
                  controller: _scrollController,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _dayCount,
                        childAspectRatio: 1,
                      ),
                  itemCount: _dayCount * _hourCount,
                  itemBuilder: (context, index) {
                    final slot = Slot(
                      dayOfWeek: index % _dayCount,
                      hour: index ~/ _dayCount,
                    );
                    final isSelected = widget.selectedSlots.contains(slot);
                    final colorScheme = Theme.of(context).colorScheme;

                    return Container(
                      key: Key('availability_slot_${slot.dayOfWeek}_${slot.hour}'),
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
