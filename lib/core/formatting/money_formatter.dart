import 'package:intl/intl.dart';

const _defaultMoneyLocale = 'es_AR';


String formatCents(int cents, {String locale = _defaultMoneyLocale}) {
  final isNegative = cents.isNegative;
  final absoluteCents = cents.abs();
  final wholeAmount = absoluteCents ~/ 100;
  final fractionalAmount = absoluteCents % 100;
  final formatter = NumberFormat.decimalPattern(locale);
  final sign = isNegative ? '-' : '';
  final fractionalText = fractionalAmount.toString().padLeft(2, '0');

  return '$sign${formatter.format(wholeAmount)}${formatter.symbols.DECIMAL_SEP}$fractionalText';
}


int parseToCents(String input) {
  final normalizedInput = input.replaceAll(RegExp(r'\s+'), '');
  final match = RegExp(
    r'^([+-]?)(?:(\d{1,3}([.,])\d{3}(?:\3\d{3})*)|(\d+))(?:([.,])(\d{1,2}))?$',
  ).firstMatch(normalizedInput);

  if (match == null) {
    throw FormatException('Invalid money amount: $input');
  }

  final groupingSeparator = match.group(3);
  final decimalSeparator = match.group(5);
  if (groupingSeparator != null && groupingSeparator == decimalSeparator) {
    throw FormatException('Ambiguous money amount: $input');
  }

  final wholeText = (match.group(2) ?? match.group(4))!.replaceAll(
    RegExp(r'[.,]'),
    '',
  );
  final fractionalText = match.group(6) ?? '';
  final wholeCents = int.parse(wholeText) * 100;
  final fractionalCents = fractionalText.isEmpty
      ? 0
      : int.parse(fractionalText.padRight(2, '0'));
  final cents = wholeCents + fractionalCents;

  return match.group(1) == '-' ? -cents : cents;
}
