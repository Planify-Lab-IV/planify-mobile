import '../../domain/person_balance_detail.dart';

enum PersonBalanceDetailLoadStatus { loading, success, error }

// Estado de presentación para el desglose de saldo con una persona.
class PersonBalanceDetailState {
  final PersonBalanceDetail? detail;
  final PersonBalanceDetailLoadStatus loadStatus;

  const PersonBalanceDetailState({
    this.detail,
    this.loadStatus = PersonBalanceDetailLoadStatus.loading,
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
          loadStatus == other.loadStatus;

  @override
  int get hashCode => detail.hashCode ^ loadStatus.hashCode;

  @override
  String toString() {
    return 'PersonBalanceDetailState(detail: $detail, loadStatus: $loadStatus)';
  }
}
