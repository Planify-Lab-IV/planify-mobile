import '../../domain/person_balance_detail.dart';

enum PersonBalanceDetailLoadStatus { loading, success, error }

// Estado de presentación para el desglose de saldo con una persona.
class PersonBalanceDetailState {
  final PersonBalanceDetail? detail;
  final PersonBalanceDetailLoadStatus loadStatus;
  final bool isSettling;

  const PersonBalanceDetailState({
    this.detail,
    this.loadStatus = PersonBalanceDetailLoadStatus.loading,
    this.isSettling = false,
  });

  bool get isLoading => loadStatus == PersonBalanceDetailLoadStatus.loading;
  bool get isSuccess => loadStatus == PersonBalanceDetailLoadStatus.success;
  bool get hasLoadError => loadStatus == PersonBalanceDetailLoadStatus.error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonBalanceDetailState &&
          runtimeType == other.runtimeType &&
          detail == other.detail &&
          isSettling == other.isSettling &&
          loadStatus == other.loadStatus;

  @override
  int get hashCode => Object.hash(detail, loadStatus, isSettling);

  PersonBalanceDetailState copyWith({
    PersonBalanceDetail? detail,
    PersonBalanceDetailLoadStatus? loadStatus,
    bool? isSettling,
  }) => PersonBalanceDetailState(
    detail: detail ?? this.detail,
    loadStatus: loadStatus ?? this.loadStatus,
    isSettling: isSettling ?? this.isSettling,
  );

  @override
  String toString() {
    return 'PersonBalanceDetailState(detail: $detail, loadStatus: $loadStatus)';
  }
}
