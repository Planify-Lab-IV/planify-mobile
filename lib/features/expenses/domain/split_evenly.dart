// Divide gastos entre las distintas partes
List<int> splitEvenly(int totalCents, int count) {
  if (totalCents < 0) {
    throw ArgumentError.value(totalCents, 'totalCents', 'must not be negative');
  }
  if (count <= 0) {
    throw ArgumentError.value(count, 'count', 'must be greater than zero');
  }

  final baseAmount = totalCents ~/ count;
  final remainder = totalCents % count;
  final parts = List<int>.filled(count, baseAmount);
  parts[count - 1] += remainder;

  return parts;
}
