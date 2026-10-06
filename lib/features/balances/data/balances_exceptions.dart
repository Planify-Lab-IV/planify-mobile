sealed class BalancesException implements Exception {
  const BalancesException();
}

class NetworkBalancesException extends BalancesException {
  const NetworkBalancesException();
}

class InvalidBalancesResponseException extends BalancesException {
  const InvalidBalancesResponseException();
}
