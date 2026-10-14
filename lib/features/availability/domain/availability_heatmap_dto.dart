import 'slot_heatmap_dto.dart';

class AvailabilityHeatmapDto {
  final int totalParticipants;
  final List<SlotHeatmapDto> slots;

  AvailabilityHeatmapDto({
    required this.totalParticipants,
    required List<SlotHeatmapDto> slots,
  }) : slots = List.unmodifiable(slots) {
    if (totalParticipants < 0) {
      throw ArgumentError.value(
        totalParticipants,
        'totalParticipants',
        'must be greater than or equal to 0',
      );
    }
  }
}
