import '../../domain/availability_heatmap_dto.dart';

enum AvailabilityHeatmapLoadStatus { loading, success, error }

class AvailabilityHeatmapState {
  final AvailabilityHeatmapDto? heatmap;
  final AvailabilityHeatmapLoadStatus loadStatus;

  const AvailabilityHeatmapState({
    this.heatmap,
    this.loadStatus = AvailabilityHeatmapLoadStatus.loading,
  });

  bool get isLoading => loadStatus == AvailabilityHeatmapLoadStatus.loading;
  bool get hasLoadError => loadStatus == AvailabilityHeatmapLoadStatus.error;

  AvailabilityHeatmapState copyWith({
    AvailabilityHeatmapDto? heatmap,
    AvailabilityHeatmapLoadStatus? loadStatus,
  }) {
    return AvailabilityHeatmapState(
      heatmap: heatmap ?? this.heatmap,
      loadStatus: loadStatus ?? this.loadStatus,
    );
  }
}
