import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/slot.dart';

class AvailabilityGrid extends StatefulWidget {
  final Set<Slot> selectedSlots;
  final ValueChanged<Slot> onToggleSlot;
  final ValueChanged<Slot> onMarkSlot;
  final List<String> dayLabels;
  final bool isEnabled;

  const AvailabilityGrid({
    super.key,
    required this.selectedSlots,
    required this.onToggleSlot,
    required this.onMarkSlot,
    required this.dayLabels,
    this.isEnabled = true,
  }) : assert(dayLabels.length == 7);

  @override
  State<AvailabilityGrid> createState() => _AvailabilityGridState();
}

class _AvailabilityGridState extends State<AvailabilityGrid> {
  static const _dayCount = 7;
  static const _gridColumnCount = _dayCount + 1;
  static const _hourCount = 24;
  static const _slotSpacing = AppSpacing.sm;
  static const _slotAspectRatio = 1.25;
  static const _slotBorderRadius = 6.0;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Slot? _slotAt(Offset position, double gridWidth) {
    final cellWidth =
        (gridWidth - (_slotSpacing * (_gridColumnCount - 1))) /
        _gridColumnCount;
    final cellHeight = cellWidth / _slotAspectRatio;
    final cellStride = cellWidth + _slotSpacing;
    final rowStride = cellHeight + _slotSpacing;
    final contentY = position.dy + _scrollController.offset;
    final column = (position.dx / cellStride).floor();
    final dayOfWeek = column - 1;
    final hour = (contentY / rowStride).floor();

    final isInColumnGap = position.dx - (column * cellStride) > cellWidth;
    final isInRowGap = contentY - (hour * rowStride) > cellHeight;

    if (dayOfWeek < 0 ||
        dayOfWeek >= _dayCount ||
        hour < 0 ||
        hour >= _hourCount ||
        isInColumnGap ||
        isInRowGap) {
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
                const SizedBox(width: _slotSpacing),
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
                    const SizedBox(width: _slotSpacing),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                return AbsorbPointer(
                  absorbing: !widget.isEnabled,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) => _toggleAt(
                      details.localPosition,
                      constraints.maxWidth,
                    ),
                    onLongPressStart: (details) =>
                        _markAt(details.localPosition, constraints.maxWidth),
                    onLongPressMoveUpdate: (details) =>
                        _markAt(details.localPosition, constraints.maxWidth),
                    child: SizedBox(
                      height: gridHeight,
                      child: GridView.builder(
                        key: const Key('availability_grid'),
                        controller: _scrollController,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _gridColumnCount,
                              crossAxisSpacing: _slotSpacing,
                              mainAxisSpacing: _slotSpacing,
                              childAspectRatio: _slotAspectRatio,
                            ),
                        itemCount: _gridColumnCount * _hourCount,
                        itemBuilder: (context, index) {
                          final column = index % _gridColumnCount;
                          final hour = index ~/ _gridColumnCount;

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

                          final slot = Slot(
                            dayOfWeek: column - 1,
                            hour: hour,
                          );
                          final isSelected = widget.selectedSlots.contains(
                            slot,
                          );
                          final colorScheme = Theme.of(context).colorScheme;

                          return Container(
                            key: Key(
                              'availability_slot_${slot.dayOfWeek}_${slot.hour}',
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                _slotBorderRadius,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
