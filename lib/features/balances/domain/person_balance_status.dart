enum PersonBalanceStatus {
  pay,
  pending,
  settled;

  bool get isPay => this == PersonBalanceStatus.pay;
  bool get isPending => this == PersonBalanceStatus.pending;
  bool get isSettled => this == PersonBalanceStatus.settled;
}
