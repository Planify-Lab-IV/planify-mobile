enum DebtStatus {
  pending,
  settled;

  bool get isPending => this == DebtStatus.pending;
  bool get isSettled => this == DebtStatus.settled;
}
