import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/availability_repository.dart';
import 'availability_heatmap_state.dart';

class AvailabilityHeatmapNotifier
    extends StateNotifier<AvailabilityHeatmapState> {
  final AvailabilityRepository repository;
  final String eventId;

  AvailabilityHeatmapNotifier({required this.repository, required this.eventId})
    : super(const AvailabilityHeatmapState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loadStatus: AvailabilityHeatmapLoadStatus.loading);

    try {
      final heatmap = await repository.heatmap(eventId);
      if (!mounted) return;
      state = state.copyWith(
        heatmap: heatmap,
        loadStatus: AvailabilityHeatmapLoadStatus.success,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loadStatus: AvailabilityHeatmapLoadStatus.error);
    }
  }
}
